//
//  VideoExporterSpec.swift
//  KoalaTeaVideoEditor_Example
//
//  Created by Craig Holliday on 8/29/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Quick
import Nimble
import SwifterSwift
import CoreMedia
    import KoalaTeaVideoEditor

class VideoExporterSpec: QuickSpec {
    override func spec() {
        var thirtySecondAsset: VideoAsset {
            return VideoAsset(url: Bundle(for: VideoExporterSpec.self).url(forResource: "SampleVideo_1280x720_5mb", withExtension: "mp4")!)
        }

        let videoExportOperationQueue: CompletionOperationQueue = {
            let asyncOperationQueue = CompletionOperationQueue(completion: nil)
            asyncOperationQueue.maxConcurrentOperationCount = 1
            return asyncOperationQueue
        }()

        describe("video exporter") {
            var fileUrls: [URL] = []
            var progressToCheck: Double = 0

            afterEach {
                fileUrls.forEach({ (fileUrl) in
                    FileHelpers.removeFileAtURL(fileURL: fileUrl)
                })

                fileUrls = []
                progressToCheck = 0
            }

//            context("export video") {
//                it("should complete export with progress") {
//                    let start = Date()
//
//                    let finalAsset = thirtySecondAsset.changeStartTime(to: 5.0).changeEndTime(to: 10.0)
//
//                    VideoExporter
//                        .createVideoExportOperationWithoutCrop(videoAsset: finalAsset,
//                                                success: { returnedFileUrl in
//                            print(returnedFileUrl, "exported file url")
//                            fileUrl = returnedFileUrl
//
//                            print(Date().timeIntervalSince(start), "<- End Time For Export")
//                        }, failure: { (error) in
//                            expect(error).to(beNil())
//                            fail()
//                        })
//
//                    expect(progressToCheck).toEventually(beGreaterThan(0.5), timeout: 30)
//                    expect(fileUrl).toEventuallyNot(beNil(), timeout: 30)
//
//                    // Check just saved local video
//                    let savedVideo = VideoAsset(url: fileUrl!)
//                    let firstVideoTrack = savedVideo.urlAsset.getFirstVideoTrack()
//                    expect(firstVideoTrack?.naturalSize.width).to(equal(1280))
//                    expect(firstVideoTrack?.naturalSize.height).to(equal(720))
//                    expect(firstVideoTrack?.asset?.duration.seconds).to(equal(5))
//                }
//            }

            context("export video with watermark") {
                it("should complete export with progress") {
                    let start = Date()

                    let finalAsset = thirtySecondAsset.changeStartTime(to: 0.0).changeEndTime(to: 5.0)

                    let watermarkView = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 100))
                    watermarkView.layer.rasterizationScale = 2.0
                    watermarkView.layer.contentsScale = 2.0
                    watermarkView.layer.shouldRasterize = true
                    watermarkView.layer.backgroundColor = UIColor.red.cgColor

                    let operation = try! VideoExporter.createVideoExportOperationWithoutCrop(videoAsset: finalAsset, overlayView: watermarkView)

                    var errors: [Error] = []
                    var totalTime: TimeInterval = 0

                    operation.progressBlock = { session in
                        progressToCheck = session.progress.double
                    }

                    operation.completionBlock = {
                        fileUrls.append(operation.fileUrl!)
                        totalTime = Date().timeIntervalSince(start)
                        if let error = operation.error {
                            errors.append(error)
                        }
                    }

                    videoExportOperationQueue.addOperation(operation)

                    expect(operation).toNot(beNil())
                    expect(errors).toEventually(beEmpty())
                    expect(fileUrls).toEventually(haveCount(1), timeout: 120)
                    expect(progressToCheck).toEventually(beGreaterThanOrEqualTo(0.50), timeout: 120, pollInterval: 0.01)
                    print(totalTime, "Total time for all operations")

                    // Check just saved local video
                    let savedVideo = VideoAsset(url: fileUrls.first!)
                    let firstVideoTrack = savedVideo.urlAsset.getFirstVideoTrack()
                    expect(firstVideoTrack?.naturalSize.width).toEventually(equal(1280))
                    expect(firstVideoTrack?.naturalSize.height).toEventually(equal(720))
                    expect(firstVideoTrack?.asset?.duration.seconds).toEventually(equal(5))
                }
            }

            context("export multiple video clips") {
                it("should generate 3 time ranges between duration") {
                    let ranges = VideoAsset.getTimeRanges(for: 30, clipLength: 10)
                    expect(ranges.count).to(be(3))
                    expect(ranges.first?.start.seconds).to(be(0.0))
                    expect(ranges.first?.end.seconds).to(be(10.0))
                    expect(ranges[1].start.seconds).to(be(10.0))
                    expect(ranges[1].end.seconds).to(be(20.0))
                    expect(ranges.last?.start.seconds).to(be(20.0))
                    expect(ranges.last?.end.seconds).to(be(30.0))
                }

                it("should complete export with progress") {
                    let start = Date()

                    let watermarkView = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 100))
                    watermarkView.layer.rasterizationScale = 2.0
                    watermarkView.layer.contentsScale = 2.0
                    watermarkView.layer.shouldRasterize = true
                    watermarkView.layer.backgroundColor = UIColor.red.cgColor

                    var errors: [Error] = []
                    var totalTime: TimeInterval = 0

                    let _ = VideoExporter.exportClips(videoAsset: thirtySecondAsset,
                                                      clipLength: 10,
                                                      queue: .main,
                                                      overlayView: watermarkView,
                                                      progress: { progress in
                                                        progressToCheck = progress
                    },
                                                      completion: { (exportedUrls, returnedErrors) in
                                                        fileUrls = exportedUrls
                                                        errors = returnedErrors
                                                        totalTime = Date().timeIntervalSince(start)
                    })

                    expect(errors).to(beEmpty())
                    expect(fileUrls).toEventually(haveCount(3), timeout: 120)
                    expect(progressToCheck).toEventually(beGreaterThanOrEqualTo(0.50), timeout: 120, pollInterval: 0.01)
                    print(totalTime, "Total time for all operations")
                }
            }
        }
    }
}

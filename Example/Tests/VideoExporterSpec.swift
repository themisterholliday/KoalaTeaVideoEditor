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
        var thirtySecondAsset: ExportableVideoAsset {
            return ExportableVideoAsset(url: Bundle(for: VideoExporterSpec.self).url(forResource: "SampleVideo_1280x720_5mb", withExtension: "mp4")!)
        }

        let videoExportOperationQueue: CompletionOperationQueue = {
            let asyncOperationQueue = CompletionOperationQueue(completion: nil)
            asyncOperationQueue.maxConcurrentOperationCount = 1
            return asyncOperationQueue
        }()

        describe("video exporter") {
            var fileUrls: [URL] = []
            var progressToCheck: Float = 0

            afterEach {
                // Comment out if manual testing
                fileUrls.forEach({ (fileUrl) in
                    FileHelpers.removeFileAtURL(fileURL: fileUrl)
                })

                print(fileUrls, "––– fileURLs –––")
                fileUrls = []
                progressToCheck = 0
            }

            describe("basic exports") {
                it("should complete export with crop and trim to 5 seconds") {
                    let finalAsset = thirtySecondAsset.changeStartTime(to: 0.0).changeEndTime(to: 5.0)
                    let finalAssetFrame = CGRect(x: 0, y: 0, width: 1280, height: 720)
                    finalAsset.frame = finalAssetFrame

                    let exportSize: VideoExporter.VideoExportSizes = ._720x1280

                    let cropWidth = exportSize.size.width / 2
                    let cropHeight = exportSize.size.height / 2
                    let cropFrame = CGRect(x: (finalAssetFrame.size.width / 2) - (cropWidth / 2), y: 0, width: cropWidth, height: cropHeight)

                    finalAsset.cropViewFrame = cropFrame
                    let operation = try! VideoExporter.createVideoExportOperationWithCrop(videoAsset: finalAsset, finalExportSize: exportSize)

                    operation.progressBlock = { progressOperation in
                        progressToCheck = progressOperation.progress
                    }

                    operation.completed = { completedOperation in
                        guard let fileURL = completedOperation.fileUrl else {
                            fail()
                            return
                        }
                        fileUrls.append(fileURL)
                    }

                    operation.start()

                    expect(progressToCheck).toEventually(beGreaterThan(0.5), timeout: 30)
                    expect(fileUrls.first).toEventuallyNot(beNil(), timeout: 30)

                    // Check just saved local video
                    let savedVideo = ExportableVideoAsset(url: fileUrls.first!)
                    let firstVideoTrack = savedVideo.urlAsset.getFirstVideoTrack()
                    expect(firstVideoTrack?.naturalSize.width).to(equal(exportSize.size.width))
                    expect(firstVideoTrack?.naturalSize.height).to(equal(exportSize.size.height))
                    expect(firstVideoTrack?.asset?.duration.seconds).to(equal(5))
                }

                it("should complete export without crop and trim to 5 seconds") {
                    let finalAsset = thirtySecondAsset.changeStartTime(to: 0.0).changeEndTime(to: 5.0)
                    let finalAssetFrame = CGRect(x: 0, y: 0, width: 1280, height: 720)
                    finalAsset.frame = finalAssetFrame

                    let exportSize: VideoExporter.VideoExportSizes = ._1280x720
                    let operation = try! VideoExporter.createVideoExportOperationWithoutCrop(videoAsset: finalAsset)

                    operation.progressBlock = { progressOperation in
                        progressToCheck = progressOperation.progress
                    }

                    operation.completed = { completedOperation in
                        guard let fileURL = completedOperation.fileUrl else {
                            fail()
                            return
                        }
                        fileUrls.append(fileURL)
                    }

                    operation.start()

                    expect(progressToCheck).toEventually(beGreaterThan(0.5), timeout: 30)
                    expect(fileUrls.first).toEventuallyNot(beNil(), timeout: 30)

                    // Check just saved local video
                    let savedVideo = ExportableVideoAsset(url: fileUrls.first!)
                    let firstVideoTrack = savedVideo.urlAsset.getFirstVideoTrack()
                    expect(firstVideoTrack?.naturalSize.width).to(equal(exportSize.size.width))
                    expect(firstVideoTrack?.naturalSize.height).to(equal(exportSize.size.height))
                    expect(firstVideoTrack?.asset?.duration.seconds).to(equal(5))
                }
            }

            describe("export video with watermark") {
                it("should complete export with progress") {
                    let finalAsset = thirtySecondAsset.changeStartTime(to: 0.0).changeEndTime(to: 5.0)
                    finalAsset.frame = CGRect(origin: .zero, size: thirtySecondAsset.naturalAssetSize ?? .zero)

                    let watermarkView = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 100))
                    watermarkView.layer.rasterizationScale = 2.0
                    watermarkView.layer.contentsScale = 2.0
                    watermarkView.layer.shouldRasterize = true
                    watermarkView.layer.backgroundColor = UIColor.red.cgColor

                    let operation = try! VideoExporter.createVideoExportOperationWithoutCrop(videoAsset: finalAsset, overlayView: watermarkView)

                    var errors: [Error] = []

                    operation.progressBlock = { session in
                        progressToCheck = session.progress
                    }

                    operation.completed = { completedOperation in
                        fileUrls.append(completedOperation.fileUrl!)
                        if let error = operation.error {
                            errors.append(error)
                        }
                    }

                    videoExportOperationQueue.addOperation(operation)

                    expect(operation).toNot(beNil())
                    expect(errors).toEventually(beEmpty())
                    expect(fileUrls).toEventually(haveCount(1), timeout: 120)
                    expect(progressToCheck).toEventually(beGreaterThanOrEqualTo(0.50), timeout: 120, pollInterval: 0.01)

                    // Check just saved local video
                    let savedVideo = ExportableVideoAsset(url: fileUrls.first!)
                    let firstVideoTrack = savedVideo.urlAsset.getFirstVideoTrack()
                    expect(firstVideoTrack?.naturalSize.width).toEventually(equal(1280))
                    expect(firstVideoTrack?.naturalSize.height).toEventually(equal(720))
                    expect(firstVideoTrack?.asset?.duration.seconds).toEventually(equal(5))
                }
            }

            describe("export multiple video clips") {
                it("should generate 3 time ranges between duration") {
                    let ranges = ExportableVideoAsset.getTimeRanges(for: 30, clipLength: 10)
                    expect(ranges.count).to(be(3))
                    expect(ranges.first?.start.seconds).to(be(0.0))
                    expect(ranges.first?.end.seconds).to(be(10.0))
                    expect(ranges[1].start.seconds).to(be(10.0))
                    expect(ranges[1].end.seconds).to(be(20.0))
                    expect(ranges.last?.start.seconds).to(be(20.0))
                    expect(ranges.last?.end.seconds).to(be(30.0))
                }

                it("should complete export with progress") {
                    let watermarkView = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 100))
                    watermarkView.layer.rasterizationScale = 2.0
                    watermarkView.layer.contentsScale = 2.0
                    watermarkView.layer.shouldRasterize = true
                    watermarkView.layer.backgroundColor = UIColor.red.cgColor

                    var errors: [Error] = []

                    let finalAsset = thirtySecondAsset
                    finalAsset.frame = CGRect(origin: .zero, size: thirtySecondAsset.naturalAssetSize ?? .zero)

                    let _ = VideoExporter.exportClips(videoAsset: finalAsset,
                                                      clipLength: 10,
                                                      queue: .main,
                                                      overlayView: watermarkView,
                                                      progress: { progress in
                                                        progressToCheck = progress
                    },
                                                      completion: { (exportedUrls, returnedErrors) in
                                                        fileUrls = exportedUrls
                                                        errors = returnedErrors
                    })

                    expect(errors).to(beEmpty())
                    expect(fileUrls).toEventually(haveCount(3), timeout: 90)
                    expect(progressToCheck).toEventually(beGreaterThanOrEqualTo(0.50), timeout: 90, pollInterval: 0.01)
                }
            }
        }
    }
}

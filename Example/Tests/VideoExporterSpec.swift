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

//        describe("Video Asset Methods") {
//            context("generateClippedAssets") {
//                it("generates two clipped assets around 15 seconds long") {
//                    let assets = thirtySecondAsset.generateClippedAssets(for: 15)
//
//                    let firstAsset = assets.first
//                    expect(firstAsset?.timePoints.startTime.seconds).to(equal(0))
//                    expect(firstAsset?.timePoints.endTime.seconds).to(equal(15))
//
//                    let lastAsset = assets.last
//                    expect(lastAsset?.timePoints.startTime.seconds).to(equal(15))
//                    expect(lastAsset?.timePoints.endTime.seconds).to(equal(29.568))
//                }
//            }
//        }

        describe("video exporter") {
            var fileUrl: URL?
            var progressToCheck: Float = 0

            afterEach {
                if let url = fileUrl {
                    // Remove this line to manually review exported videos
                    FileHelpers.removeFileAtURL(fileURL: url)
                }

                fileUrl = nil
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

//            context("export video with watermark") {
//                it("should complete export with progress") {
//                    let start = Date()
//
//                    let finalAsset = thirtySecondAsset.changeStartTime(to: 0.0).changeEndTime(to: 5.0)
//
//                    let watermarkView = UIImageView(frame: CGRect(x: 0, y: 0, width: 200, height: 100))
//                    watermarkView.contentMode = .scaleAspectFit
//                    watermarkView.image = UIImage(named: "long_story_watermark")
//                    watermarkView.layer.rasterizationScale = 2.0
//                    watermarkView.layer.contentsScale = 2.0
//                    watermarkView.layer.shouldRasterize = true
//
//                    VideoExporter
//                        .createVideoExportOperationWithoutCrop(videoAsset: finalAsset,
//                                                watermarkView: watermarkView,
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

            context("export clipped video") {
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

                fit("should complete export with progress") {
                    let start = Date()

                    let watermarkView = UIImageView(frame: CGRect(x: 0, y: 0, width: 200, height: 100))
                    watermarkView.contentMode = .scaleAspectFit
                    watermarkView.image = UIImage(named: "long_story_watermark")
                    watermarkView.layer.rasterizationScale = 2.0
                    watermarkView.layer.contentsScale = 2.0
                    watermarkView.layer.shouldRasterize = true
                    watermarkView.layer.backgroundColor = UIColor.red.cgColor

                    watermarkView.layer.addFadeInAnimation(beginTime: 4.0, duration: 0.0)
                    watermarkView.layer.addFadeOutAnimation(beginTime: 2.0, duration: 0.0)

                    var urls: [URL]?

                    let operation = VideoExporter.exportClips(videoAsset: thirtySecondAsset,
                                                              clipLength: 10,
                                                              queue: .main,
                                                              watermarkView: watermarkView,
                                                              completed: { (exportedUrls, errors) in
                                                                urls = exportedUrls
                                                                expect(errors).to(beEmpty())
                                                                print(Date().timeIntervalSince(start), "<- End Time For Export")
                    })

//                    operation.operations.forEach({ operation in
//                        operation.progressBlock = { _ in
//                            print(operation.progress)
//                        }
//                    })

//                    operation.completionBlock = {
//                        print(urls, "urls")
//                    }

                    expect(urls).toEventually(haveCount(3), timeout: 120)
                }
            }
        }
    }
}

extension CALayer {
    func addStrokeEndAnimation(toValue: Double, beginTime: Double, duration: Double) {
        let animation = CABasicAnimation(keyPath: #keyPath(CAShapeLayer.strokeEnd))
        animation.fromValue = 0
        animation.toValue = toValue
        animation.beginTime = beginTime
        animation.duration = duration
        animation.autoreverses = false
        animation.isRemovedOnCompletion = false
        animation.fillMode = CAMediaTimingFillMode.forwards

        self.add(animation, forKey: UUID().uuidString)
    }

    func addAnimatePositionAlongPath(path: CGPath, beginTime: Double, duration: Double, repeatCount: Float) {
        let animation = CAKeyframeAnimation(keyPath: #keyPath(CALayer.position))
        animation.path = path
        animation.calculationMode = CAAnimationCalculationMode.paced
        animation.duration = duration
        animation.beginTime = beginTime
        animation.isRemovedOnCompletion = false
        animation.repeatCount = repeatCount

        self.add(animation, forKey: UUID().uuidString)
    }

    func addFadeAnimation(fromValue: Float, toValue: Float, beginTime: Double, duration: Double) {
        let animation = CABasicAnimation(keyPath: #keyPath(CALayer.opacity))
        animation.fromValue = fromValue
        animation.toValue = toValue
        animation.beginTime = beginTime
        animation.duration = duration
        animation.autoreverses = false
        animation.isRemovedOnCompletion = false
        animation.fillMode = CAMediaTimingFillMode.forwards

        self.add(animation, forKey: UUID().uuidString)
    }

    func addFadeInAnimation(beginTime: Double, duration: Double) {
        self.addFadeAnimation(fromValue: 0.0, toValue: 1.0, beginTime: beginTime, duration: duration)
    }

    func addFadeOutAnimation(beginTime: Double, duration: Double) {
        self.addFadeAnimation(fromValue: 1.0, toValue: 0.0, beginTime: beginTime, duration: duration)
    }

    func addRotateAnimation(duration: Double, repeatCount: Float) {
        let animation = CABasicAnimation(keyPath: "transform.rotation")
        animation.fromValue = 0.0
        animation.toValue = CGFloat(.pi * 2.0)
        animation.duration = duration
        animation.repeatCount = repeatCount

        self.add(animation, forKey: UUID().uuidString)
    }
}

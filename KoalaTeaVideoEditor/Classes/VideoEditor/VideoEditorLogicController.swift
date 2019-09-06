////
////  VideoEditorController.swift
////
////  Created by Craig Holliday on 8/29/18.
////
//
//import Foundation
//import KoalaTeaAssetPlayer
//
//public class VideoEditorLogicController {
//    public typealias StateHandler = (VideoEditorVCState) -> Void
//    public typealias SetupHandler = (_ player: AssetPlayer) -> Void
//    public typealias TrackingHandler = (_ startTime: Double, _ currentTime: Double) -> Void
//
//    private var videoAsset: ExportableVideoAsset
//    private let assetplayer: AssetPlayer
//    private var previousStartTime: Double = 0.0
//    private var sendWithAudioOn: Bool = false
//    private var wasPlayingThenStartedScroll: Bool = false
//
//    public var setupHandler: SetupHandler = { _ in }
//    // Handler for tracking AssetPlayer playback
//    public var trackingHandler: TrackingHandler = { _,_ in }
//    public var stateHandler: StateHandler = { _ in }
//
//    public init(assetPlayer: AssetPlayer,
//                videoAsset: ExportableVideoAsset,
//                setupHandler: SetupHandler?,
//                trackingHandler: TrackingHandler?) {
//        self.videoAsset = videoAsset.changeStartTime(to: 0.0).changeEndTime(to: 5.0)
//
//        assetplayer = assetPlayer
//        assetplayer.delegate = self
//
//        if let handler = setupHandler {
//            self.setupHandler = handler
//        }
//
//        if let handler = trackingHandler {
//            self.trackingHandler = handler
//        }
//    }
//
//    public func handle(intent: VideoEditorVCIntentions, stateHandler: @escaping StateHandler) {
//        self.stateHandler = stateHandler
//
//        switch intent {
//        case .setup(let video):
//            self.stateHandler(.loading)
//            self.assetplayer.handle(action: .setup(with: video, startMuted: true))
//            self.assetplayer.handle(action: .play)
//        case .didTapPauseButton:
//            self.assetplayer.handle(action: .pause)
//            self.stateHandler(.paused)
//        case .didTapPlayButton:
//            self.assetplayer.handle(action: .play)
//            self.stateHandler(.playing)
//        case .didTapMuteButton:
//            self.assetplayer.handle(action: .changeIsMuted(to: true))
//            self.stateHandler(.muted)
//            self.sendWithAudioOn = false
//        case .didTapUnmuteButton:
//            self.assetplayer.handle(action: .changeIsMuted(to: false))
//            self.stateHandler(.unmuted)
//            self.sendWithAudioOn = true
//        case .didStartScrolling:
//            if self.assetplayer.state == .playing {
//                self.wasPlayingThenStartedScroll = true
//            }
//            self.assetplayer.handle(action: .pause)
//            self.stateHandler(.paused)
//        case .didScroll(let time):
//            let newCurrentTime = self.getNewTimeFromOffset(currentTime: assetplayer.currentTime,
//                                                           newStartTime: time.startTime,
//                                                           previousStartTime: previousStartTime)
//            assetplayer.handle(action: .seekToTimeInSeconds(time: newCurrentTime))
//            assetplayer.handle(action: .changeStartTimeForLoop(to: time.startTime))
//            assetplayer.handle(action: .changeEndTimeForLoop(to: time.endTime))
//
//            previousStartTime = time.startTime
//
//            if wasPlayingThenStartedScroll {
//                self.assetplayer.handle(action: .play)
//                self.stateHandler(.playing)
//            } else {
//                self.assetplayer.handle(action: .pause)
//                self.stateHandler(.paused)
//            }
//            self.wasPlayingThenStartedScroll = false
//
//            // A fix to handle a less than 0 start time
//            switch time.startTime > 0 {
//            case true:
//                self.videoAsset = self.videoAsset.changeStartTime(to: time.startTime).changeEndTime(to: time.endTime)
//            case false:
//                self.videoAsset = self.videoAsset.changeStartTime(to: 0.0).changeEndTime(to: 5.0)
//            }
//        case .didTapContinueButton(let playerViewFrame, let playerViewTransform, let playerViewAdjustedOrigin, let cropViewFrame, let viewController):
//            self.assetplayer.handle(action: .pause)
//            self.stateHandler(.loading)
//
//            let finalExportableVideoAsset = self.videoAsset
//                .withChangingFrame(to: playerViewFrame)
//                .withChangingViewTransform(to: playerViewTransform)
//                .withChangingAdjustedOrigin(to: playerViewAdjustedOrigin)
//
//            // Export cropped video
//            VideoExporter
//                .exportThemeVideo(with: finalExportableVideoAsset, cropViewFrame: cropViewFrame, progress: { (progress) in
//                    print("VideoEditorLogicController: video exporting progress = \(progress)")
//                }, success: { (videoUrl) in
//                    print("VideoEditorLogicController: Video Saved")
//                    viewController.delegate?.videoEditorDidFinishEditingVideo(videoEditor: viewController, videoURL: videoUrl, sendWithAudioOn: self.sendWithAudioOn)
//                }) { (error) in
//                    print("VideoEditorLogicController: export Error \(error)")
//                    self.stateHandler(.exportError)
//            }
//        case .didDisappear:
//            self.assetplayer.handle(action: .pause)
//            self.stateHandler(.none)
//        }
//    }
//
//    private func getNewTimeFromOffset(currentTime: Double, newStartTime: Double, previousStartTime: Double) -> Double {
//        let offset = newStartTime - previousStartTime
//        return currentTime + offset
//    }
//}
//
//extension VideoEditorLogicController: AssetPlayerDelegate {
//    public func currentAssetDidChange(_ player: AssetPlayer) {}
//
//    public func playerIsSetup(_ player: AssetPlayer) {
//        assetplayer.handle(action: .changeStartTimeForLoop(to: 0.0))
//        assetplayer.handle(action: .changeEndTimeForLoop(to: 5.0))
//
//        setupHandler(player)
//        stateHandler(.muted)
//        stateHandler(.playing)
//    }
//
//    public func playerPlaybackStateDidChange(_ player: AssetPlayer) {}
//
//    public func playerCurrentTimeDidChange(_ player: AssetPlayer) {}
//
//    public func playerCurrentTimeDidChangeInMilliseconds(_ player: AssetPlayer) {
//        self.trackingHandler(player.startTimeForLoop, player.currentTime)
//    }
//
//    public func playerPlaybackDidEnd(_ player: AssetPlayer) {}
//
//    public func playerIsLikelyToKeepUp(_ player: AssetPlayer) {}
//
//    public func playerBufferTimeDidChange(_ player: AssetPlayer) {}
//}

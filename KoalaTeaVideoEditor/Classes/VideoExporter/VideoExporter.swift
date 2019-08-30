//
//  VideoHelpers.swift
//  koala-tea-video-editor
//
//  Created by Craig Holliday on 1/7/18.
//  Copyright © 2018 Koala Tea. All rights reserved.
//

import AVFoundation
import UIKit
import KoalaTeaAssetPlayer

/// Exporter for VideoAssets
public class VideoExporter {
    private enum VideoManagerError: Error {
        case FailedError(reason: String)
        case CancelledError
        case UnknownError
        case NoFirstVideoTrack
        case NoFirstAudioTrack
    }
    
    /**
     Supported Final Video Sizes
     
     - _1080x1080: 1080 width by 1080 height
     - _1280x720: 1280 width by 720 height
     - _720x1280: 720 width by 1280 height
     - _1920x1080: 1920 width by 1080 height
     - _1080x1920: 1080 width by 1920 height
     */
    public enum VideoExportSizes {
        case _1080x1080
        case _1024x1024
        case _1280x720
        case _720x1280
        case _1920x1080
        case _1080x1920
        case _1280x1024_twitter
        
        typealias RawValue = CGSize
        
        var rawValue: RawValue {
            switch self {
            case ._1080x1080:
                return CGSize(width: 1080, height: 1080)
            case ._1024x1024:
                return CGSize(width: 1024, height: 1024)
            case ._1280x720:
                return CGSize(width: 1280, height: 720)
            case ._720x1280:
                return CGSize(width: 720, height: 1280)
            case ._1920x1080:
                return CGSize(width: 1920, height: 1080)
            case ._1080x1920:
                return CGSize(width: 1080, height: 1920)
            case ._1280x1024_twitter:
                return CGSize(width: 1280, height: 1024)
            }
        }
        
        init?(string: String?) {
            switch string {
            case "720x1280":
                self = ._720x1280
            case "1080x1920":
                self = ._1080x1920
            default:
                return nil
            }
        }
    }
}

extension VideoExporter {
    /**
     Exports a video to the disk from AVMutableComposition and AVMutableVideoComposition.
     
     - Parameters:
     - avMutableComposition: Layer composition of everything except video
     - avMutatableVideoComposition: Video composition
     
     - progress: Returns progress every second.
     - success: Completion for when the video is saved successfully.
     - failure: Completion for when the video failed to save.
     */
    @discardableResult private static func exportVideoToDiskFrom(avMutableComposition: AVMutableComposition,
                                                                 avMutatableVideoComposition: AVMutableVideoComposition,
                                                                 success: @escaping (_ fileUrl: URL) -> Void,
                                                                 failure: @escaping (Error) -> Void) -> VideoExportOperation? {
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            failure(VideoManagerError.FailedError(reason: "Get File Path Error"))
            return nil
        }
        
        guard let appName = Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String else {
            failure(VideoManagerError.FailedError(reason: "Cannot find App Name"))
            return nil
        }
        
        let dateString = Date.currentDateTimeString
        let uuid = UUID().uuidString
        let fileURL = documentDirectory.appendingPathComponent("\(appName)-\(dateString)-\(uuid).mp4")
        
        // Remove any file at URL because if file exists assetExport will fail
        FileHelpers.removeFileAtURL(fileURL: fileURL)
        
        // Create AVAssetExportSession
        guard let assetExportSession = AVAssetExportSession(asset: avMutableComposition, presetName: AVAssetExportPresetHighestQuality) else {
            failure(VideoManagerError.FailedError(reason: "Can't create asset exporter"))
            return nil
        }
        assetExportSession.videoComposition = avMutatableVideoComposition
        assetExportSession.outputFileType = AVFileType.mp4
        assetExportSession.shouldOptimizeForNetworkUse = true
        assetExportSession.outputURL = fileURL
        
        let videoExport = VideoExportSession(avExportSession: assetExportSession, fileUrl: fileURL)
        
        let operation = VideoExportOperation(export: videoExport)
        
        operation.completionBlock = {
            switch operation.sessionState {
            case .idle:
                break
            case .successful:
                guard let fileUrl = operation.fileUrl else {
                    failure(operation.error ?? VideoManagerError.UnknownError)
                    return
                }
                success(fileUrl)
            case .failed:
                failure(operation.error ?? VideoManagerError.UnknownError)
            case .cancelled:
                failure(operation.error ?? VideoManagerError.UnknownError)
            }
        }
        
        return operation
    }
    
    private static func videoCompositionInstructionFor(compositionTrack: AVCompositionTrack,
                                                       assetTrack: AVAssetTrack,
                                                       assetFrameAdjustedOrigin: CGPoint,
                                                       playerViewFrame: CGRect,
                                                       playerViewTransform: CGAffineTransform,
                                                       widthMultiplier: CGFloat,
                                                       heightMultiplier: CGFloat,
                                                       cropViewFrame: CGRect) -> AVMutableVideoCompositionLayerInstruction {
        let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionTrack)
        
        let assetInfo = assetTrack.assetInfo
        let assetTransform = assetTrack.preferredTransform
        
        let exportSizeRatio = min(widthMultiplier, heightMultiplier)
        
        // Get scale
        let targetAssetWidth = playerViewFrame.width * exportSizeRatio
        let targetAssetHeight = playerViewFrame.height * exportSizeRatio
        
        // Flip width and height on portrait
        var targetView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: targetAssetWidth, height: targetAssetHeight)))
        
        if assetInfo.isPortrait {
            targetView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: targetAssetHeight, height: targetAssetWidth)))
        }
        
        let naturalView = UIView(frame: CGRect(origin: .zero, size: assetTrack.naturalSize))
        
        let naturalSizeToTargetSizeTransform = CGAffineTransform(from: naturalView.originalFrame, toRect: targetView.originalFrame)
        let onlyScaleForTarget = CGAffineTransform(scaleX: naturalSizeToTargetSizeTransform.getScale, y: naturalSizeToTargetSizeTransform.getScale)
        
        // Get origin
        let targetAssetX: CGFloat = (assetFrameAdjustedOrigin.x - cropViewFrame.minX) * exportSizeRatio
        let targetAssetY: CGFloat = (assetFrameAdjustedOrigin.y - cropViewFrame.minY) * exportSizeRatio
        
        // player view transforms
        let originTransform = CGAffineTransform(translationX: targetAssetX, y: targetAssetY)
        let playerViewRotationTransform = CGAffineTransform(rotationAngle: playerViewTransform.currentRotation)
        let playerViewScaleTransform = CGAffineTransform(scaleX: playerViewTransform.getScale, y: playerViewTransform.getScale)
        
        let exportTransform = assetTransform
            .concatenating(onlyScaleForTarget)
            .concatenating(playerViewScaleTransform)
            .concatenating(playerViewRotationTransform)
            .concatenating(originTransform)
        
        instruction.setTransform(exportTransform, at: CMTime.zero)
        
        return instruction
    }
    
    private static func createSimpleVideoCompositionInstruction(compositionTrack: AVCompositionTrack,
                                                                assetTrack: AVAssetTrack) -> AVMutableVideoCompositionLayerInstruction {
        let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionTrack)
        
        let assetTransform = assetTrack.preferredTransform
        instruction.setTransform(assetTransform, at: CMTime.zero)
        return instruction
    }
}

extension AVAssetTrack {
    var assetInfo: (orientation: UIImage.Orientation, isPortrait: Bool) {
        let assetTransform = self.preferredTransform
        let assetInfo = VideoExporterOrientationHelper.orientationFromTransform(transform: assetTransform)
        return assetInfo
    }
}

// MARK: Generic Export Method
extension VideoExporter {
    /// Export video from VideoAsset with a cropping view to a final export size.
    ///
    /// - Parameters:
    ///   - videoAsset: VideoAsset to export
    ///   - cropViewFrame: frame of crop view that will determine crop of final exported video. Crop View frame is in relation to a CanvasViewFrame
    ///   - finalExportSize: final export size the video will be after completeing
    ///   - progress: progress of export
    ///   - success: successful completion of export
    ///   - failure: export failure
    public static func exportVideoWithCrop(videoAsset: VideoAsset,
                                           cropViewFrame: CGRect,
                                           finalExportSize: VideoExportSizes,
                                           progress: @escaping (Float) -> Void,
                                           success: @escaping (_ fileUrl: URL) -> Void,
                                           failure: @escaping (Error) -> Void) {
        let exportVideoSize = finalExportSize.rawValue
        
        // Canvas view has to be same aspect ratio as export video size
        guard cropViewFrame.size.getAspectRatio() == exportVideoSize.getAspectRatio() else {
            assertionFailure("Selected export size's aspect ratio: \(exportVideoSize.getAspectRatio()) does not equal Cropped View Frame's aspect ratio: \(cropViewFrame.size.getAspectRatio())")
            failure(VideoManagerError.FailedError(reason: "Issue with Crop View Frame Size"))
            return
        }
        
        // 1 - Create AVMutableComposition object. This object will hold your AVMutableCompositionTrack instances.
        let mixComposition = AVMutableComposition()
        
        // 2 - Create video tracks
        guard let firstTrack = mixComposition.addMutableTrack(withMediaType: .video,
                                                              preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else {
                                                                failure(VideoManagerError.FailedError(reason: "Failed To Create Video Track"))
                                                                return
        }
        guard let assetFirstVideoTrack = videoAsset.urlAsset.getFirstVideoTrack() else {
            failure(VideoManagerError.NoFirstVideoTrack)
            return
        }
        
        // Attach timerange for first video track
        do {
            try firstTrack.insertTimeRange(videoAsset.timeRange,
                                           of: assetFirstVideoTrack,
                                           at: CMTime.zero)
        } catch {
            failure(VideoManagerError.FailedError(reason: "Failed To Insert Time Range For Video Track"))
            return
        }
        
        // 2.1
        let mainInstruction = AVMutableVideoCompositionInstruction()
        let durationOfExportedVideo = CMTimeRange(start: CMTime.zero, duration: videoAsset.durationInCMTime)
        mainInstruction.timeRange = durationOfExportedVideo
        
        // Multipliers to scale height and width of video to final export size
        let heightMultiplier: CGFloat = exportVideoSize.height / cropViewFrame.height
        let widthMultiplier: CGFloat = exportVideoSize.width / cropViewFrame.width
        // 2.2
        let firstInstruction = self.videoCompositionInstructionFor(compositionTrack: firstTrack,
                                                                   assetTrack: assetFirstVideoTrack,
                                                                   assetFrameAdjustedOrigin: videoAsset.adjustedOrigin,
                                                                   playerViewFrame: videoAsset.frame,
                                                                   playerViewTransform: videoAsset.viewTransform,
                                                                   widthMultiplier: widthMultiplier,
                                                                   heightMultiplier: heightMultiplier,
                                                                   cropViewFrame: cropViewFrame)
        
        // 2.3
        mainInstruction.layerInstructions = [firstInstruction]
        
        let avMutableVideoComposition = AVMutableVideoComposition()
        avMutableVideoComposition.instructions = [mainInstruction]
        guard let framerate = videoAsset.framerate else {
            failure(VideoManagerError.FailedError(reason: "No Framerate for Asset"))
            return
        }
        avMutableVideoComposition.frameDuration = CMTimeMake(value: 1, timescale: Int32(framerate))
        avMutableVideoComposition.renderSize = exportVideoSize
        
        // 3 - Audio track
        guard let audioAsset = videoAsset.urlAsset.getFirstAudioTrack() else {
            failure(VideoManagerError.FailedError(reason: "No First Audio Track"))
            return
        }
        
        let audioTrack = mixComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: 0)
        do {
            try audioTrack?.insertTimeRange(videoAsset.timeRange,
                                            of: audioAsset,
                                            at: CMTime.zero)
        } catch {
            failure(VideoManagerError.FailedError(reason: "Failed To Insert Time Range For Audio Track"))
        }
        
        // 4 Export Video
        self.exportVideoToDiskFrom(avMutableComposition: mixComposition, avMutatableVideoComposition: avMutableVideoComposition, success: success, failure: failure)
    }
    
    @discardableResult public static func createVideoExportOperationWithoutCrop(videoAsset: VideoAsset, watermarkView: UIView? = nil) throws -> VideoExportOperation {
        // 1 - Create AVMutableComposition object. This object will hold your AVMutableCompositionTrack instances.
        let mixComposition = AVMutableComposition()
        
        // 2 - Create video tracks
        guard let firstTrack = mixComposition.addMutableTrack(withMediaType: .video,
                                                              preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else {
                                                                throw VideoManagerError.FailedError(reason: "Failed To Create Video Track")
        }
        guard let assetFirstVideoTrack = videoAsset.urlAsset.getFirstVideoTrack() else {
            throw VideoManagerError.NoFirstVideoTrack
        }
        
        // Attach timerange for first video track
        try firstTrack.insertTimeRange(videoAsset.timeRange, of: assetFirstVideoTrack, at: CMTime.zero)
        
        // 2.1
        let mainInstruction = AVMutableVideoCompositionInstruction()
        mainInstruction.timeRange = CMTimeRange(start: CMTime.zero, duration: videoAsset.durationInCMTime)
        
        // 2.2
        let firstInstruction = self.createSimpleVideoCompositionInstruction(compositionTrack: firstTrack, assetTrack: assetFirstVideoTrack)
        
        // 2.3
        mainInstruction.layerInstructions = [firstInstruction]
        
        let avMutableVideoComposition = AVMutableVideoComposition()
        avMutableVideoComposition.instructions = [mainInstruction]
        guard let framerate = videoAsset.framerate else {
            throw VideoManagerError.FailedError(reason: "No Framerate for Asset")
        }
        avMutableVideoComposition.frameDuration = CMTimeMake(value: 1, timescale: Int32(framerate))
        avMutableVideoComposition.renderSize = assetFirstVideoTrack.naturalSize
        
        var finalAVMutable = avMutableVideoComposition

        if let copyOfLayer = watermarkView?.layer.copyOfLayer {
            finalAVMutable = self.addLayer(copyOfLayer, to: avMutableVideoComposition)
        }
        
        // 3 - Audio track
        guard let audioAsset = videoAsset.urlAsset.getFirstAudioTrack() else {
            throw VideoManagerError.FailedError(reason: "No First Audio Track")
        }
        
        let audioTrack = mixComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: 0)
        try audioTrack?.insertTimeRange(videoAsset.timeRange, of: audioAsset, at: CMTime.zero)
        
        // 4 Export Video
        
        // @TODO: move to create directory method
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw VideoManagerError.FailedError(reason: "Get File Path Error")
        }
        
        guard let appName = Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String else {
            throw VideoManagerError.FailedError(reason: "Cannot find App Name")
        }
        
        let dateString = Date.currentDateTimeString
        let uuid = UUID().uuidString
        let fileURL = documentDirectory.appendingPathComponent("\(appName)-\(dateString)-\(uuid).mp4")
        
        // Remove any file at URL because if file exists assetExport will fail
        FileHelpers.removeFileAtURL(fileURL: fileURL)
        
        // @TODO: move to create asset session method
        // Create AVAssetExportSession
        guard let assetExportSession = AVAssetExportSession(asset: mixComposition,
                                                            presetName: AVAssetExportPresetHighestQuality) else {
                                                                throw VideoManagerError.FailedError(reason: "Can't create asset exporter")
        }
        assetExportSession.videoComposition = finalAVMutable
        assetExportSession.outputFileType = AVFileType.mp4
        assetExportSession.shouldOptimizeForNetworkUse = true
        assetExportSession.outputURL = fileURL
        
        let videoExport = VideoExportSession(avExportSession: assetExportSession, fileUrl: fileURL)
        
        return VideoExportOperation(export: videoExport)
    }
    
    // @TODO: move somewhere else
    private static func addLayer(_ layer: CALayer, to avMutableVideoComposition: AVMutableVideoComposition) -> AVMutableVideoComposition {
        let frameForLayers = CGRect(origin: .zero, size: avMutableVideoComposition.renderSize)
        let videoLayer = CALayer()
        videoLayer.frame = frameForLayers
        
        let parentlayer = CALayer()
        parentlayer.frame = frameForLayers
        parentlayer.isGeometryFlipped = true
        parentlayer.addSublayer(videoLayer)
        
        // Actually add layer to parent layer
        parentlayer.addSublayer(layer)
        
        avMutableVideoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentlayer)
        return avMutableVideoComposition
    }
}

extension VideoExporter {
    private static var videoExportOperationQueue: CompletionOperationQueue = {
        let asyncOperationQueue = CompletionOperationQueue(completion: nil)
        asyncOperationQueue.maxConcurrentOperationCount = 1
        return asyncOperationQueue
    }()

    public static func exportClips(videoAsset: VideoAsset,
                                   clipLength: Int,
                                   queue: DispatchQueue,
                                   watermarkView: UIView? = nil,
                                   completed: @escaping (_ fileUrls: [URL], _ errors: [Error]) -> Void) -> CompletionOperationQueue {
        let assets = VideoAsset.generateClippedAssets(for: clipLength, from: videoAsset)
        
        let completionOperation = VideoExporter.videoExportOperationQueue
        let operations = assets.compactMap { (asset) -> VideoExportOperation? in
            return try? VideoExporter.createVideoExportOperationWithoutCrop(videoAsset: asset, watermarkView: watermarkView)
        }

        completionOperation.completionBlock = {
            let fileUrls = operations.compactMap({ $0.fileUrl })
            let errors = operations.compactMap({ $0.error })
            completed(fileUrls, errors)
        }

        operations.forEach { (operation) in
            videoExportOperationQueue.addOperation(operation)
            operation.progressBlock = { progress in
                print(progress, "testing")
            }
        }
        
        return completionOperation
    }
}

extension Date {
    static var currentDateTimeString: String {
        let utcTimeZone = TimeZone(abbreviation: "UTC")
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.timeZone = utcTimeZone
        return dateFormatter.string(from: Date())
    }
}

extension CALayer {
    var copyOfLayer: CALayer? {
        let archive = NSKeyedArchiver.archivedData(withRootObject: self)
        return NSKeyedUnarchiver.unarchiveObject(with: archive) as? CALayer
    }
}

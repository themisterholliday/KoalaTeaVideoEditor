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
public enum VideoExporter {
    private enum VideoManagerError: Error {
        case FailedError(reason: String)
        case CancelledError
        case UnknownError
        case NoFirstVideoTrack
        case NoFirstAudioTrack
    }
}

extension VideoExporter {
    private static func exportVideoToDiskFrom(avMutableComposition: AVMutableComposition, avMutatableVideoComposition: AVMutableVideoComposition) throws -> VideoExportOperation {
        let fileURL = try buildAppDateTimeMP4FileURL()
        
        // Remove any file at URL because if file exists assetExport will fail
        FileHelpers.removeFileAtURL(fileURL: fileURL)

        let assetExportSession = try buildAVAssetExportSession(mixComposition: avMutableComposition, videoComposition: avMutatableVideoComposition, outputURL: fileURL)
        
        let videoExport = VideoExportSession(avExportSession: assetExportSession, fileUrl: fileURL)
        return VideoExportOperation(export: videoExport)
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

// MARK: Export Methods
extension VideoExporter {
    public static func createVideoExportOperationWithCrop(videoAsset: ExportableVideoAsset, finalExportSize: VideoExportSizes) throws -> VideoExportOperation {
        try validate(videoAsset, using: .isCropping)

        let exportVideoSize = finalExportSize.size
        let cropViewFrame = videoAsset.cropViewFrame
        
        // Canvas view has to be same aspect ratio as export video size
        guard cropViewFrame.size.getAspectRatio() == exportVideoSize.getAspectRatio() else {
            assertionFailure("Selected export size's aspect ratio: \(exportVideoSize.getAspectRatio()) does not equal Cropped View Frame's aspect ratio: \(cropViewFrame.size.getAspectRatio())")
            throw VideoManagerError.FailedError(reason: "Issue with Crop View Frame Size")
        }
        
        // 1 - Create AVMutableComposition object. This object will hold your AVMutableCompositionTrack instances.
        let mixComposition = AVMutableComposition()
        
        // 2 - Create video tracks
        guard let firstTrack = mixComposition.addMutableTrack(withMediaType: .video, preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else {
            throw VideoManagerError.FailedError(reason: "Failed To Create Video Track")
        }
        guard let assetFirstVideoTrack = videoAsset.urlAsset.getFirstVideoTrack() else {
            throw VideoManagerError.NoFirstVideoTrack
        }
        
        // Attach timerange for first video track
        try firstTrack.insertTimeRange(videoAsset.timeRange, of: assetFirstVideoTrack, at: CMTime.zero)
        
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
            throw VideoManagerError.FailedError(reason: "No Framerate for Asset")
        }
        avMutableVideoComposition.frameDuration = CMTimeMake(value: 1, timescale: Int32(framerate))
        avMutableVideoComposition.renderSize = exportVideoSize
        
        // 3 - Audio track
        guard let audioAsset = videoAsset.urlAsset.getFirstAudioTrack() else {
            throw VideoManagerError.FailedError(reason: "No First Audio Track")
        }
        
        let audioTrack = mixComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: 0)
        try audioTrack?.insertTimeRange(videoAsset.timeRange, of: audioAsset, at: CMTime.zero)
        
        // 4 Export Video
        return try self.exportVideoToDiskFrom(avMutableComposition: mixComposition, avMutatableVideoComposition: avMutableVideoComposition)
    }

    public static func createVideoExportOperationWithoutCrop(videoAsset: ExportableVideoAsset, overlayView: UIView? = nil) throws -> VideoExportOperation {
        try validate(videoAsset, using: .noCropping)

        // 1 - Create AVMutableComposition object. This object will hold your AVMutableCompositionTrack instances.
        let mixComposition = AVMutableComposition()
        
        // 2 - Create video tracks
        guard let firstTrack = mixComposition.addMutableTrack(withMediaType: .video, preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else {
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

        if let copyOfLayer = overlayView?.layer.copyOfLayer {
            finalAVMutable = AVMutableVideoCompositionLayerAdder.addLayer(copyOfLayer, to: avMutableVideoComposition)
        }
        
        // 3 - Audio track
        guard let audioAsset = videoAsset.urlAsset.getFirstAudioTrack() else {
            throw VideoManagerError.FailedError(reason: "No First Audio Track")
        }
        
        let audioTrack = mixComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: 0)
        try audioTrack?.insertTimeRange(videoAsset.timeRange, of: audioAsset, at: CMTime.zero)
        
        // 4 Export Video
        let fileURL = try buildAppDateTimeMP4FileURL()
        
        // Remove any file at URL because if file exists assetExport will fail
        FileHelpers.removeFileAtURL(fileURL: fileURL)

        let assetExportSession = try buildAVAssetExportSession(mixComposition: mixComposition, videoComposition: finalAVMutable, outputURL: fileURL)
        
        let videoExport = VideoExportSession(avExportSession: assetExportSession, fileUrl: fileURL)

        return VideoExportOperation(export: videoExport)
    }
}

// MARK: - Helper Methods
extension VideoExporter {
    static func buildAVAssetExportSession(mixComposition: AVMutableComposition, videoComposition: AVMutableVideoComposition, outputURL: URL) throws -> AVAssetExportSession {
        guard let assetExportSession = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality) else {
            throw VideoManagerError.FailedError(reason: "Can't create asset exporter")
        }
        assetExportSession.videoComposition = videoComposition
        assetExportSession.outputFileType = AVFileType.mp4
        assetExportSession.shouldOptimizeForNetworkUse = true
        assetExportSession.outputURL = outputURL
        return assetExportSession
    }

    static func buildAppDateTimeMP4FileURL() throws -> URL {
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw VideoManagerError.FailedError(reason: "Get File Path Error")
        }

        guard let appName = Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String else {
            throw VideoManagerError.FailedError(reason: "Cannot find App Name")
        }

        let dateString = Date.currentDateTimeString
        let uuid = UUID().uuidString
        return documentDirectory.appendingPathComponent("\(appName)-\(dateString)-\(uuid).mp4")
    }
}

// MARK: - ExportableVideoAsset Validator
private extension Validator where Value == ExportableVideoAsset {
    static var noCropping: Validator {
        return Validator { asset in
            try validate(
                asset.frame != .zero,
                errorMessage: "Frame cannot be zero"
            )
        }
    }

    static var isCropping: Validator {
        return Validator { asset in
            try validate(
                asset.frame != .zero,
                errorMessage: "Frame cannot be zero"
            )

            try validate(
                asset.cropViewFrame != .zero,
                errorMessage: "Crop frame cannot be zero when cropping"
            )
        }
    }
}

// MARK: - Helper Extensions
private extension Date {
    static var currentDateTimeString: String {
        let utcTimeZone = TimeZone(abbreviation: "UTC")
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.timeZone = utcTimeZone
        return dateFormatter.string(from: Date())
    }
}

private extension CALayer {
    var copyOfLayer: CALayer? {
        let archive = NSKeyedArchiver.archivedData(withRootObject: self)
        return NSKeyedUnarchiver.unarchiveObject(with: archive) as? CALayer
    }
}

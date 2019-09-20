//
//  VideoClipsExporter.swift
//  KoalaTeaAssetPlayer
//
//  Created by Craig Holliday on 9/19/19.
//

import AVFoundation

public final class VideoClipsExporter {
    public init() {}

    private var videoExportOperationQueue: CompletionOperationQueue = {
        let asyncOperationQueue = CompletionOperationQueue(completion: nil)
        asyncOperationQueue.maxConcurrentOperationCount = 1
        return asyncOperationQueue
    }()

    public func exportClips(videoAsset: ExportableVideoAsset,
                            clipLength: Int,
                            queue: DispatchQueue,
                            overlayView: UIView? = nil,
                            progress: @escaping (Float) -> Void,
                            completion: @escaping (_ fileUrls: [URL], _ errors: [Error]) -> Void) -> CompletionOperationQueue {
        let assets = ExportableVideoAsset.generateClippedAssets(for: clipLength, from: videoAsset)

        let completionOperation = self.videoExportOperationQueue
        let operations = assets.compactMap { (asset) -> VideoExportOperation? in
            return try? VideoExporter.createVideoExportOperationWithoutCrop(videoAsset: asset, overlayView: overlayView)
        }

        completionOperation.completionBlock = {
            let fileUrls = operations.compactMap({ $0.fileUrl })
            let errors = operations.compactMap({ $0.error })
            completion(fileUrls, errors)
        }

        var itemsProgress: [Int: Float] = [:]

        operations.enumerated().forEach { (index, operation) in
            videoExportOperationQueue.addOperation(operation)
            operation.progressBlock = { session in
                itemsProgress[index] = session.progress
                let allProgress = itemsProgress.values.reduce(0.0, +)
                progress(allProgress / operations.count.float)
            }
        }

        return completionOperation
    }
}

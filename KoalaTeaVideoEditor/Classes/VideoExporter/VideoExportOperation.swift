//
//  VideoExportOperation.swift
//  KoalaTeaAssetPlayer
//
//  Created by Craig Holliday on 8/30/19.
//

import AVFoundation

public enum VideoExportState {
    case idle, successful, failed, cancelled
}

public struct VideoExportSession {
    public let avExportSession: AVAssetExportSession
    public var progress: Float
    public var fileUrl: URL?
    public var error: Error?
    public var state: VideoExportState

    init(avExportSession: AVAssetExportSession,
         fileUrl: URL,
         progress: Float = 0.0,
         state: VideoExportState = .idle,
         error: Error? = nil) {
        self.avExportSession = avExportSession
        self.fileUrl = fileUrl
        self.progress = progress
        self.state = state
        self.error = error
    }
}

public class VideoExportOperation: AsynchronousOperation {
    private var exportSessionObject: VideoExportSession
    private var timer: Timer?

    public var progress: Float {
        return exportSessionObject.progress
    }

    public var fileUrl: URL? {
        return exportSessionObject.fileUrl
    }

    public var error: Error? {
        return exportSessionObject.error
    }

    public var sessionState: VideoExportState {
        return exportSessionObject.state
    }

    public var progressBlock: (_ uploadModel: VideoExportSession) -> Void = { _ in }
    public var started: (_ uploadModel: VideoExportSession) -> Void = { _ in }
    public var completed: (_ uploadModel: VideoExportSession) -> Void = { _ in }

    init(export: VideoExportSession) {
        self.exportSessionObject = export
    }

    override public func main() {
        operationQueue.addOperation {
            self.handleStart()
        }
    }

    private func handleStart() {
        self.started(exportSessionObject)

        let assetExportSession = exportSessionObject.avExportSession
        DispatchQueue.main.async {
            self.timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: { _ in
                self.handleTimerProgress(assetExportSession: assetExportSession)
            })
        }

        assetExportSession.exportAsynchronously(completionHandler: {
            self.timer?.invalidate()

            switch assetExportSession.status {
            case .completed:
                self.exportSessionObject.progress = 1.0
                self.exportSessionObject.state = .successful
                self.progressBlock(self.exportSessionObject)
                self.state = .finished
                self.completed(self.exportSessionObject)
            case .cancelled:
                let error = assetExportSession.error ?? VideoExportOperationError.CancelledError
                self.exportSessionObject.state = .cancelled
                self.exportSessionObject.error = error
                self.exportSessionObject.fileUrl = nil
                self.state = .finished
                self.completed(self.exportSessionObject)
            case .failed:
                let error = assetExportSession.error ?? VideoExportOperationError.FailedError(reason: "Asset Exporter Failed")
                self.exportSessionObject.state = .failed
                self.exportSessionObject.error = error
                self.exportSessionObject.fileUrl = nil
                self.state = .finished
                self.completed(self.exportSessionObject)
            case .unknown, .exporting, .waiting:
                // Should never arrive here
                let error = assetExportSession.error ?? VideoExportOperationError.UnknownError
                self.exportSessionObject.state = .failed
                self.exportSessionObject.error = error
                self.exportSessionObject.fileUrl = nil
                self.state = .finished
                self.completed(self.exportSessionObject)
            @unknown default:
                assertionFailure()
            }
        })
    }

    override public func cancel() {
        super.cancel()
        self.exportSessionObject.avExportSession.cancelExport()
    }

    private func handleTimerProgress(assetExportSession: AVAssetExportSession) {
        self.exportSessionObject.progress = assetExportSession.progress
        self.progressBlock(self.exportSessionObject)
    }
}

extension VideoExportOperation {
    private enum VideoExportOperationError: Error {
        case FailedError(reason: String)
        case CancelledError
        case UnknownError
    }
}

public class MultiVideoExportOperation: Operation {
    public var operations: [VideoExportOperation]
    var fileUrls: [URL] {
        return operations.compactMap({ $0.fileUrl })
    }
    var errors: [Error] {
        return operations.compactMap({ $0.error })
    }

    init(operations: [VideoExportOperation]) {
        self.operations = operations
    }
}

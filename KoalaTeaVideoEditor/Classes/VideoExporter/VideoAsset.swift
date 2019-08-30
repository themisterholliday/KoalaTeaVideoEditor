//
//  VideoAsset.swift
//  KoalaTeaAssetPlayer
//
//  Created by Craig Holliday on 8/29/19.
//

import AVFoundation
import KoalaTeaAssetPlayer

public struct TimePoints {
    public var startTime: CMTime
    public var endTime: CMTime
}

extension TimePoints: Equatable {
    public static func == (lhs: TimePoints, rhs: TimePoints) -> Bool {
        return lhs.startTime == rhs.startTime &&
            lhs.endTime == rhs.endTime
    }
}

public class VideoAsset: Asset {
    /// Start and End times for export
    public private(set) var timePoints: TimePoints
    /// frame of video in relation to CanvasView to be exported
    public var frame: CGRect
    public var viewTransform: CGAffineTransform
    public var adjustedOrigin: CGPoint

    /// Framerate of Video
    public var framerate: Double? {
        guard let track = self.urlAsset.getFirstVideoTrack() else {
            assertionFailure("VideoAsset: " + "Failure getting first video track")
            return nil
        }

        return Double(track.nominalFrameRate)
    }

    public var timeRange: CMTimeRange {
        let duration = timePoints.endTime - timePoints.startTime
        return CMTimeRangeMake(start: timePoints.startTime, duration: duration)
    }

    public var duration: Double {
        return durationInCMTime.seconds
    }

    public var durationInCMTime: CMTime {
        return timePoints.endTime - timePoints.startTime
    }

    public var cropDurationInSeconds: Double {
        return self.duration > PublicConstants.MaxCropDurationInSeconds ? PublicConstants.MaxCropDurationInSeconds : self.duration
    }

    private var timeScale: Int32 {
        return Asset.PublicConstants.DefaultTimeScale
    }

    // MARK: Init
    public init(urlAsset: AVURLAsset,
                timePoints: TimePoints,
                frame: CGRect = .zero,
                viewTransform: CGAffineTransform = .identity,
                adjustedOrigin: CGPoint = .zero) {
        self.timePoints = timePoints
        self.frame = frame
        self.viewTransform = viewTransform
        self.adjustedOrigin = adjustedOrigin
        super.init(urlAsset: urlAsset)
    }

    public convenience init(url: URL) {
        let urlAsset = AVURLAsset(url: url, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
        let timePoints = TimePoints(startTime: CMTime.zero, endTime: Asset.adjustedTimeScaleDuration(for: urlAsset.duration))
        self.init(urlAsset: urlAsset, timePoints: timePoints)
    }

    public convenience init(urlAsset: AVURLAsset) {
        let timePoints = TimePoints(startTime: CMTime.zero, endTime: Asset.adjustedTimeScaleDuration(for: urlAsset.duration))
        self.init(urlAsset: urlAsset, timePoints: timePoints)
    }

    // MARK: Mutating Functions
    public func changeStartTime(to time: Double) -> VideoAsset {
        let cmTime = CMTimeMakeWithSeconds(time, preferredTimescale: Asset.PublicConstants.DefaultTimeScale)
        self.timePoints.startTime = cmTime

        if time < 0 {
            self.timePoints.startTime = .zero
        }

        return self
    }

    public func changeEndTime(to time: Double, ignoreOffset: Bool = false) -> VideoAsset {
        let cmTime = CMTimeMakeWithSeconds(time, preferredTimescale: Asset.PublicConstants.DefaultTimeScale)

        let urlAssetDuration = VideoAsset.adjustedTimeScaleDuration(for: urlAsset.duration)

        guard cmTime < urlAssetDuration else {
            var offset = CMTime(seconds: 0, preferredTimescale: Asset.PublicConstants.DefaultTimeScale)

            if !ignoreOffset {
                offset = cmTime - urlAssetDuration
            }

            let newStartTime = self.timePoints.startTime - offset

            self.timePoints.endTime = urlAssetDuration
            // Have to adjust start time before returning
            return self.changeStartTime(to: newStartTime.seconds)
        }

        self.timePoints.endTime = cmTime
        return self
    }
}

extension VideoAsset {
    public struct PublicConstants {
        static let MaxCropDurationInSeconds = 5.0
    }

    public var copy: VideoAsset {
        return VideoAsset(urlAsset: urlAsset, timePoints: timePoints, frame: frame, viewTransform: viewTransform, adjustedOrigin: adjustedOrigin)
    }
}

extension VideoAsset {
    public static func generateClippedAssets(for clipLength: Int, from asset: VideoAsset) -> [VideoAsset] {
        let ranges = VideoAsset.getTimeRanges(for: asset.duration.rounded().int, clipLength: clipLength)
        return ranges.map { (range) -> VideoAsset in
            let new = asset.copy.changeStartTime(to: range.start.seconds).changeEndTime(to: range.end.seconds, ignoreOffset: true)
            return new
        }
    }

    public static func getTimeRanges(for duration: Int, clipLength: Int) -> [CMTimeRange] {
        // @TODO: figure out how to use doubles?
        let numbers = Array(1...duration)
        let result = numbers.chunked(into: clipLength)

        return result.compactMap { (value) -> CMTimeRange? in
            guard let first = value.first, let last = value.last else {
                return nil
            }
            let start = CMTime(seconds: first.double - 1.0, preferredTimescale: Asset.PublicConstants.DefaultTimeScale)
            let end = CMTime(seconds: last.double, preferredTimescale: Asset.PublicConstants.DefaultTimeScale)
            return CMTimeRange(start: start, end: end)
        }
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

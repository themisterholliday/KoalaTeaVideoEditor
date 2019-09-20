//
//  AVAssetTrack+AssetInfo.swift
//  KoalaTeaAssetPlayer
//
//  Created by Craig Holliday on 9/19/19.
//

import AVFoundation
import KoalaTeaAssetPlayer

extension AVAssetTrack {
    var assetInfo: (orientation: UIImage.Orientation, isPortrait: Bool) {
        let assetTransform = self.preferredTransform
        let assetInfo = VideoExporterOrientationHelper.orientationFromTransform(transform: assetTransform)
        return assetInfo
    }
}

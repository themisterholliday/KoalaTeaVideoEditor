//
//  VideoExportSizes.swift
//  KoalaTeaAssetPlayer
//
//  Created by Craig Holliday on 9/19/19.
//

import Foundation

public enum VideoExportSizes {
    case _1080x1080
    case _1024x1024
    case _1280x720
    case _720x1280
    case _1920x1080
    case _1080x1920
    case _1280x1024_twitter

    public var size: CGSize {
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

    public init?(string: String?) {
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

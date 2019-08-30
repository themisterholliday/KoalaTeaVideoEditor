//
//  PlayerView.swift
//  KoalaTeaPlayer
//
//  Created by Craig Holliday on 8/4/17.
//  Copyright © 2017 Koala Tea. All rights reserved.
//

import AVFoundation
import UIKit

/// A simple `UIView` subclass that is backed by an `AVPlayerLayer` layer.
public class PlayerView: UIView {
    public var player: AVPlayer? {
        get {
            return playerLayer.player
        }

        set {
            playerLayer.player = newValue
        }
    }

    public var playerLayer: AVPlayerLayer {
        // swiftlint:disable force_cast
        return layer as! AVPlayerLayer
        // swiftlint:enable force_cast
    }

    public override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
}

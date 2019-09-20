//
//  AVMutableVideoCompositionLayerAdder.swift
//  KoalaTeaAssetPlayer
//
//  Created by Craig Holliday on 9/19/19.
//

import AVFoundation

enum AVMutableVideoCompositionLayerAdder {
    static func addLayer(_ layer: CALayer, to avMutableVideoComposition: AVMutableVideoComposition) -> AVMutableVideoComposition {
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

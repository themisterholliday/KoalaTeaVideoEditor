//
//  CompletionOperationQueue.swift
//  KoalaTeaAssetPlayer
//
//  Created by Craig Holliday on 8/30/19.
//

import Foundation

public class CompletionOperationQueue: OperationQueue {

    public var completionBlock: (() -> Void)?
    private var observation: NSKeyValueObservation?

    public init(completion: (() -> Void)? = nil) {
        self.completionBlock = completion
        super.init()
        self.observation = self.observe( \.operationCount ) { [weak self] (_, _) in
            if self?.operationCount == 0 {
                self?.completionBlock?()
            }
        }
    }
}

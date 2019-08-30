//
//  AsynchronousOperation.swift
//  KoalaTeaAssetPlayer
//
//  Created by Craig Holliday on 8/30/19.
//

import Foundation

public class AsynchronousOperation: Operation {
    enum State: String {
        case ready = "Ready"
        case executing = "Executing"
        case finished = "Finished"
        fileprivate var keyPath: String { return "is" + self.rawValue }
    }

    public override var isAsynchronous: Bool {
        return true
    }

    public override var isExecuting: Bool {
        return state == .executing
    }

    public override var isFinished: Bool {
        return state == .finished
    }

    var state = State.ready {
        willSet {
            willChangeValue(forKey: state.keyPath)
            willChangeValue(forKey: newValue.keyPath)
        }
        didSet {
            didChangeValue(forKey: state.keyPath)
            didChangeValue(forKey: oldValue.keyPath)
        }
    }

    var debugMode: Bool = false

    // Seperate OperationQueue for AsyncProcess
    lazy var operationQueue: OperationQueue = {
        let operationQueue = OperationQueue()
        operationQueue.qualityOfService = .background
        return operationQueue
    }()

    public override func start() {
        if self.isCancelled {
            state = .finished
        } else {
            state = .ready
            self.main()
        }
    }

    public override func main() {
        if self.debugMode { print("AsyncOperation \(self.name ?? "") -  Main function started") }
        if self.isCancelled {
            if self.debugMode { print("AsyncOperation \(self.name ?? "") -  Main function Cancelled") }
            state = .finished
        } else {
            if self.debugMode { print("AsyncOperation \(self.name ?? "") -  Main function Executing") }
            state = .executing
        }
        if self.debugMode { print("AsyncOperation \(self.name ?? "") -  Main function Ended") }
    }

    public override func cancel() {
        super.cancel()
        operationQueue.cancelAllOperations()
    }

    func checkIsCancelled() {
        if self.isCancelled {
            state = .finished
        }
    }
}

private class AsyncOperationExample: AsynchronousOperation {
    override func main() {
        super.main()
        if self.debugMode { print("AsyncOperationExample \(self.name ?? "") - Called async inside operation") }

        // Here write the async operation
        operationQueue.addOperation {
            // Making delay
            sleep(5)
            if self.debugMode { print("AsyncOperationExample \(self.name ?? "") - async response came") }
            // Set the state to .finished once your operation completed
            self.state = .finished
        }
    }
}

private class AsyncOperationQueueExample {
    private lazy var asyncOperationQueue: CompletionOperationQueue = {
        let asyncOperationQueue = CompletionOperationQueue { [weak self] in
            self?.completedQueue()
        }
        asyncOperationQueue.maxConcurrentOperationCount = 3
        return asyncOperationQueue
    }()

    init() {
        print("AsyncOperationExample Before Total operations: \(asyncOperationQueue.operationCount)")

        var previousOperation: AsyncOperationExample?
        for index in 1...10 {
            let operation = AsyncOperationExample()
            operation.name = "--\(index)--"
            if let previous = previousOperation {
                operation.addDependency(previous)
            }
            asyncOperationQueue.addOperation(operation)

            previousOperation = operation
        }

        print("AsyncOperationExample After Total operations: \(asyncOperationQueue.operationCount)")
        print("AsyncOperationExample After waiting for operations: \(asyncOperationQueue.operationCount)")
    }

    private func completedQueue() {
        print("Completed operation queue")
    }
}

//
//  Validator.swift
//  KoalaTeaAssetPlayer
//
//  Created by Craig Holliday on 9/5/19.
//

internal struct Validator<Value> {
    let closure: (Value) throws -> Void
}

internal struct ValidationError: LocalizedError {
    let message: String
    var errorDescription: String? { return message }
}

internal func validate(_ condition: @autoclosure () -> Bool, errorMessage messageExpression: @autoclosure () -> String) throws {
    guard condition() else {
        let message = messageExpression()
        throw ValidationError(message: message)
    }
}

func validate<T>(_ value: T,
                 using validator: Validator<T>) throws {
    try validator.closure(value)
}

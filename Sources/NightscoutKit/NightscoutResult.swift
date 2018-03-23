//
//  NightscoutResult.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 3/23/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

/// Describes the result of a call to the Nightscout API.
public enum NightscoutResult<Value> {
    case success(Value)
    case failure(NightscoutError)
}

extension NightscoutResult {
    /// Returns `true` if the result is a success and `false` if the result is a failure.
    public var isSuccess: Bool {
        switch self {
        case .success(_):
            return true
        case .failure(_):
            return false
        }
    }

    /// Returns `true` if the result is a failure and `false` if the result is a success.
    public var isFailure: Bool {
        switch self {
        case .success(_):
            return false
        case .failure(_):
            return true
        }
    }

    /// In the case of success, returns the associated value.
    /// Returns `nil` in the case of failure.
    public var value: Value? {
        switch self {
        case .success(let value):
            return value
        case .failure(_):
            return nil
        }
    }

    /// In the case of failure, returns the associated `NightscoutError`.
    /// Returns `nil` in the case of success.
    public var error: NightscoutError? {
        switch self {
        case .success(_):
            return nil
        case .failure(let error):
            return error
        }
    }

    /// In the case of success, returns the associated value.
    /// In the case of failure, throws the associated `NightscoutError`.
    /// - Throws: The associated `NightscoutError` in the case of failure.
    /// - Returns: The associated value in the case of success.
    public func unwrap() throws -> Value {
        switch self {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
}

// MARK: - Functional API

extension NightscoutResult {
    /// Evaluates the closure in the case of success, passing the unwrapped value as a parameter.
    ///
    /// Use the `map` method with a closure that does not throw.
    /// - Parameter transform: A closure that takes the success value of the `NightscoutResult` instance.
    /// - Returns: A `NightscoutResult` containing the result of the given closure. If this instance is a failure, returns the
    ///            same failure.
    public func map<T>(_ transform: (Value) -> T) -> NightscoutResult<T> {
        switch self {
        case .success(let value):
            return .success(transform(value))
        case .failure(let error):
            return .failure(error)
        }
    }

    /// Evaluates the closure in the case of success, passing the unwrapped value as a parameter.
    ///
    /// Use the `ifSuccess` function to evaluate the passed closure without modifying the `NightscoutResult` instance.
    /// - Parameter closure: A closure that takes the success value of this instance.
    /// - Returns: This `NightscoutResult` instance, unmodified.
    @discardableResult
    public func ifSuccess(_ closure: (Value) -> Void) -> NightscoutResult {
        if case .success(let value) = self { closure(value) }
        return self
    }

    /// Evaluates the closure in the case of failure, passing the unwrapped error as a parameter.
    ///
    /// Use the `ifFailure` function to evaluate the passed closure without modifying the `Result` instance.
    /// - Parameter closure: A closure that takes a `NightscoutError`.
    /// - Returns: This `NightscoutResult` instance, unmodified.
    @discardableResult
    public func ifFailure(_ closure: (NightscoutError) -> Void) -> NightscoutResult {
        if case .failure(let error) = self { closure(error) }
        return self
    }
}

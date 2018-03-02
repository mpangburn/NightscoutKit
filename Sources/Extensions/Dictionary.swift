//
//  Dictionary.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 2/23/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//


// hopefully provided by the stdlib soon: https://github.com/d-date/swift-evolution/blob/33662c3c3a2f8897de228413a75a06b704b11756/proposals/0000-introduce-compact-map-values.md
extension Dictionary {
    func compactMapValues<T>(_ transform: (Value) throws -> T?) rethrows -> [Key: T] {
        return try self.reduce(into: [Key: T](), { (result, x) in
            if let value = try transform(x.value) {
                result[x.key] = value
            }
        })
    }
}

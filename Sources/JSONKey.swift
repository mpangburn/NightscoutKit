//
//  JSONKey.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 3/7/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Foundation


/// A key into a JSON dictionary with an associated phantom type.
/// Increases type safety in parsing and recreating JSON.
struct JSONKey<T> {
    let key: String

    init(_ key: String) {
        self.key = key
    }
}

extension JSONKey: ExpressibleByStringLiteral {
    init(stringLiteral key: String) {
        self.init(key)
    }
}

extension Dictionary where Key == String, Value == Any {
    subscript<T>(jsonKey: JSONKey<T>) -> T? {
        get {
            return self[jsonKey.key] as? T
        }
        set {
            self[jsonKey.key] = newValue
        }
    }
}

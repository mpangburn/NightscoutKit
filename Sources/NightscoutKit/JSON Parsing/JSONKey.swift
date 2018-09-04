//
//  JSONKey.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 3/7/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Foundation

/// A dictionary representing a JSON object.
internal typealias JSONDictionary = [String: Any]

/// A key into a JSON dictionary with an associated phantom type.
/// Increases type safety in parsing and recreating JSON.
internal struct JSONKey<T> {
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

    subscript<T: JSONParseable>(parsingFrom jsonKey: JSONKey<T>) -> T? {
        return (self[jsonKey.key] as? T.JSONParseType).flatMap(T.parse(fromJSON:))
    }

    subscript<T: RawRepresentable>(convertingFrom jsonKey: JSONKey<T>) -> T? {
        get {
            return (self[jsonKey.key] as? T.RawValue).flatMap(T.init(rawValue:))
        }
        set {
            self[jsonKey.key] = newValue?.rawValue
        }
    }

    subscript(convertingDateFrom dateStringKey: JSONKey<String>) -> Date? {
        get {
            return self[dateStringKey].flatMap(TimeFormatter.date(from:))
        }
        set {
            self[dateStringKey] = newValue.map(TimeFormatter.string(from:))
        }
    }
}

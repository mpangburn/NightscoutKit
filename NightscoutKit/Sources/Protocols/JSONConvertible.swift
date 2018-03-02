//
//  JSONConvertible.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 2/18/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Foundation


typealias JSONDictionary = [String: Any]

/// A type that can be parsed from data.
protocol DataParseable {
    static func parse(from data: Data) throws -> Self?
}

/// A type that can be parsed from JSON data.
protocol JSONParseable: DataParseable {
    static func parse(from json: JSONDictionary) -> Self?
}

extension JSONParseable {
    static func parse(from data: Data) throws -> Self? {
        guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? JSONDictionary else {
            return nil
        }
        return parse(from: json)
    }
}

/// A type that can be converted to and from JSON data.
protocol JSONConvertible: JSONParseable, RawRepresentable where RawValue == JSONDictionary { }

extension JSONConvertible {
    public init?(rawValue: RawValue) {
        guard let parsed = Self.parse(from: rawValue) else {
            return nil
        }
        self = parsed
    }
}

extension Array /*: DataParseable */ where Element: JSONParseable {
    static func parse(from data: Data) throws -> [Element] {
        guard let dictionaries = try JSONSerialization.jsonObject(with: data, options: []) as? [JSONDictionary] else {
            return []
        }
        let items = dictionaries.flatMap(Element.parse)
        assert(dictionaries.count == items.count)
        return items
    }
}

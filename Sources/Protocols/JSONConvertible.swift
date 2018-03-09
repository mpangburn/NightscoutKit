//
//  JSONConvertible.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 2/18/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

typealias JSONDictionary = [String: Any]

/// A type that can be parsed from JSON data.
protocol JSONParseable: DataParseable {
    associatedtype JSONParseType
    static func parse(fromJSON json: JSONParseType) -> Self?
}

extension JSONParseable {
    static func parse(fromData data: Data) throws -> Self? {
        guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? JSONParseType else {
            return nil
        }
        return parse(fromJSON: json)
    }
}

/// A type that can be represented as JSON.
protocol JSONRepresentable: DataRepresentable {
    associatedtype JSONRepresentation
    var jsonRepresentation: JSONRepresentation { get }
}

extension JSONRepresentable {
    func data() throws -> Data {
        return try JSONSerialization.data(withJSONObject: jsonRepresentation, options: [])
    }
}

/// A type that can be converted to and from JSON.
protocol JSONConvertible: JSONParseable, JSONRepresentable, RawRepresentable where JSONParseType == JSONRepresentation, RawValue == JSONRepresentation { }

extension JSONConvertible {
    public init?(rawValue: RawValue) {
        guard let parsed = Self.parse(fromJSON: rawValue) else {
            return nil
        }
        self = parsed
    }

    public var rawValue: RawValue {
        return jsonRepresentation
    }
}

// MARK: - Conditional conformance

extension Array /*: JSONParseable */ where Element: JSONParseable {
    typealias JSONParseType = [Element.JSONParseType]

    static func parse(fromJSON jsonArray: JSONParseType) -> [Element]? {
        return jsonArray.flatMap(Element.parse(fromJSON:))
    }

    // Can be removed post-conditional conformance
    static func parse(fromData data: Data) throws -> [Element]? {
        guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? JSONParseType else {
            return nil
        }
        return parse(fromJSON: json)
    }
}

extension Array /*: JSONRepresentable */ where Element: JSONRepresentable {
    typealias JSONRepresentation = [Element.JSONRepresentation]

    var jsonRepresentation: JSONRepresentation {
        return map { $0.jsonRepresentation }
    }

    // Can be removed post-conditional conformance
    func data() throws -> Data {
        return try JSONSerialization.data(withJSONObject: jsonRepresentation, options: [])
    }
}

extension Array /*: JSONConvertible */ where Element: JSONConvertible { }

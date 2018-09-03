//
//  NightscoutIdentifier.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 5/10/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Foundation


/// A type used to identify Nightscout entries, treatments, profile records, and device statuses.
public struct NightscoutIdentifier: Hashable, Codable {
    internal let value: String

    private static let idLength = 24
    private static let hexadecimalCharacters = Array("0123456789abcdef")

    /// Generates a new Nightscout identifier.
    public init() {
        self.value = .randomString(ofLength: NightscoutIdentifier.idLength, consistingOfCharactersIn: NightscoutIdentifier.hexadecimalCharacters)
    }

    internal init(_ value: String) {
        self.value = value
    }
}

extension NightscoutIdentifier: CustomStringConvertible {
    public var description: String {
        return value
    }
}

// MARK: - JSON

extension NightscoutIdentifier: JSONParseable {
    enum Key {
        static let id: JSONKey<String> = "_id"
    }

    static func parse(fromJSON json: JSONDictionary) -> NightscoutIdentifier? {
        return json[Key.id].map(NightscoutIdentifier.init)
    }
}

// MARK: - Extensions

private extension String {
    static func randomString<C: RandomAccessCollection>(
        ofLength length: Int,
        consistingOfCharactersIn characters: C
    ) -> String where C.Element == Character {
        precondition(length >= 0 && characters.count > 0)
        return String((0..<length).map { _ in characters.randomElement()! })
    }
}

//
//  NightscoutStatus.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 3/7/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

/// The status of a Nightscout site.
/// This type stores data such as the Nightscout version and the user's settings.
public struct NightscoutStatus {
    /// The version of Nightscout in use.
    public let version: String

    /// The user's Nightscout settings.
    public let settings: NightscoutSettings
}

// MARK: - JSON

extension NightscoutStatus: JSONParseable {
    typealias JSONParseType = JSONDictionary

    private enum Key {
        static let version: JSONKey<String> = "version"
        static let settings: JSONKey<NightscoutSettings> = "settings"
    }

    static func parse(fromJSON statusJSON: JSONDictionary) -> NightscoutStatus? {
        guard
            let version = statusJSON[Key.version],
            let settings = statusJSON[parsingFrom: Key.settings]
        else {
            return nil
        }

        return NightscoutStatus(
            version: version,
            settings: settings
        )
    }
}

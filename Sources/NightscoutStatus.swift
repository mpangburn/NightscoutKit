//
//  NightscoutStatus.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 3/7/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

public struct NightscoutStatus {
    public let version: String
    public let settings: NightscoutSettings
}

// MARK: - JSON

extension NightscoutStatus: JSONParseable {
    typealias JSONParseType = JSONDictionary

    private enum Key {
        static let version: JSONKey<String> = "version"
        static let settingsDictionary: JSONKey<JSONDictionary> = "settings"
    }

    static func parse(fromJSON statusJSON: JSONDictionary) -> NightscoutStatus? {
        guard
            let version = statusJSON[Key.version],
            let settings = statusJSON[Key.settingsDictionary].flatMap(NightscoutSettings.parse(fromJSON:))
        else {
            return nil
        }

        return NightscoutStatus(
            version: version,
            settings: settings
        )
    }
}

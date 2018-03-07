//
//  NightscoutSettings.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 2/23/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

public struct NightscoutSettings {
    public let units: BloodGlucoseUnit
    public let title: String

    static let `default` = NightscoutSettings(units: .milligramsPerDeciliter, title: "Nightscout")
}

// MARK: - JSON Parsing

extension NightscoutSettings: JSONParseable {
    typealias JSONParseType = JSONDictionary

    private enum Key {
        static let settingsDictionary: JSONKey<JSONDictionary> = "settings"
        static let unitString: JSONKey<String> = "units"
        static let title: JSONKey<String> = "customTitle"
    }

    static func parse(fromJSON statusJSON: JSONDictionary) -> NightscoutSettings? {
        guard
            let settingsDictionary = statusJSON[Key.settingsDictionary],
            let units = settingsDictionary[Key.unitString].flatMap(BloodGlucoseUnit.init(rawValue:))
        else {
            return nil
        }

        return NightscoutSettings(
            units: units,
            title: settingsDictionary[Key.title] ?? NightscoutSettings.default.title
        )
    }
}

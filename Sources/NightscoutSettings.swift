//
//  NightscoutSettings.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 2/23/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Foundation


public struct NightscoutSettings {
    public let units: BloodGlucoseUnit
    public let title: String

    static let `default` = NightscoutSettings(units: .milligramsPerDeciliter, title: "Nightscout")
}

// MARK: - JSON Parsing

extension NightscoutSettings: JSONParseable {
    private enum Key {
        static let settings = "settings"
        static let unitString = "units"
        static let title = "customTitle"
    }

    static func parse(from statusJSON: JSONDictionary) -> NightscoutSettings? {
        guard
            let settingsDictionary = statusJSON[Key.settings] as? JSONDictionary,
            let unitsString = settingsDictionary[Key.unitString] as? String,
            let units = BloodGlucoseUnit(rawValue: unitsString)
        else {
            return nil
        }

        return NightscoutSettings(
            units: units,
            title: (settingsDictionary[Key.title] as? String) ?? NightscoutSettings.default.title
        )
    }
}

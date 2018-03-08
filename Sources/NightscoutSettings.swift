//
//  NightscoutSettings.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 2/23/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

public struct NightscoutSettings {
    public let title: String
    public let units: BloodGlucoseUnit
    public let targetBloodGlucoseRange: ClosedRange<Double> // TODO: is this in `units`, or always in mg/dL?
}

// MARK: - JSON

extension NightscoutSettings: JSONParseable {
    typealias JSONParseType = JSONDictionary

    private enum Key {
        static let title: JSONKey<String> = "customTitle"
        static let unitString: JSONKey<String> = "units"
        static let thresholdsDictionary: JSONKey<JSONDictionary> = "thresholds"
        static let bgTargetBottom: JSONKey<Double> = "bgTargetBottom"
        static let bgTargetTop: JSONKey<Double> = "bgTargetTop"
    }

    private static let defaultTitle = "Nightscout"

    static func parse(fromJSON settingsJSON: JSONDictionary) -> NightscoutSettings? {
        guard
            let units = settingsJSON[Key.unitString].flatMap(BloodGlucoseUnit.init(rawValue:)),
            let thresholdsDictionary = settingsJSON[Key.thresholdsDictionary],
            let bgTargetBottom = thresholdsDictionary[Key.bgTargetBottom],
            let bgTargetTop = thresholdsDictionary[Key.bgTargetTop]
        else {
            return nil
        }

        return NightscoutSettings(
            title: settingsJSON[Key.title] ?? NightscoutSettings.defaultTitle,
            units: units,
            targetBloodGlucoseRange: bgTargetBottom...bgTargetTop
        )
    }
}

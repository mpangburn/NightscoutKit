//
//  NightscoutSettings.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 2/23/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

/// Nightscout settings. This type stores data such as the title of the user's Nightscout site,
/// their preferred blood glucose units, and their target blood glucose range as displayed in the Nightscout graph.
public struct NightscoutSettings {
    /// The title of the user's Nightscout site.
    public let title: String

    /// The user's preferred blood glucose units.
    public let bloodGlucoseUnits: BloodGlucoseUnit

    /// The user's target blood glucose range as displayed in the Nightscout graph.
    public let targetBloodGlucoseRange: ClosedRange<Double> // TODO: is this in `units`, or always in mg/dL?
}

// MARK: - JSON

extension NightscoutSettings: JSONParseable {
    typealias JSONParseType = JSONDictionary

    private enum Key {
        static let title: JSONKey<String> = "customTitle"
        static let units: JSONKey<BloodGlucoseUnit> = "units"
        static let thresholdsDictionary: JSONKey<JSONDictionary> = "thresholds"
        static let bgTargetBottom: JSONKey<Double> = "bgTargetBottom"
        static let bgTargetTop: JSONKey<Double> = "bgTargetTop"
    }

    private static let defaultTitle = "Nightscout"

    static func parse(fromJSON settingsJSON: JSONDictionary) -> NightscoutSettings? {
        guard
            let units = settingsJSON[convertingFrom: Key.units],
            let thresholdsDictionary = settingsJSON[Key.thresholdsDictionary],
            let bgTargetBottom = thresholdsDictionary[Key.bgTargetBottom],
            let bgTargetTop = thresholdsDictionary[Key.bgTargetTop]
        else {
            return nil
        }

        return .init(
            title: settingsJSON[Key.title] ?? NightscoutSettings.defaultTitle,
            bloodGlucoseUnits: units,
            targetBloodGlucoseRange: bgTargetBottom...bgTargetTop
        )
    }
}

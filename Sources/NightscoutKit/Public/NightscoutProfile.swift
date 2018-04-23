//
//  NightscoutProfile.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 2/23/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Foundation


// TODO: It makes logical sense to store blood glucose units in the profile,
// but doing so would break the JSON parsing structure.

/// A Nightscout profile.
/// This type stores data such as a user's carb ratio, basal rate, insulin sensitivity, and blood glucose target schedules; duration of active insulin (DIA); and carb absorption rate during activity.
public struct NightscoutProfile {
    /// A generic daily schedule item.
    public struct ScheduleItem<Value> {
        /// The time interval since midnight at which the item is scheduled.
        let startTime: TimeInterval

        /// The value of the schedule item.
        let value: Value
    }

    /// A carb ratio schedule.
    /// Schedule item are specified in grams per unit of insulin (g/U).
    public typealias CarbRatioSchedule = [ScheduleItem<Int>]

    /// A basal rate schedule.
    /// Schedule items are specified in units of insulin per hour (U/hr).
    public typealias BasalRateSchedule = [ScheduleItem<Double>]

    /// An insulin sensitivity schedule.
    /// Schedule items are specified in <blood glucose unit> per unit of insulin.
    /// Blood glucose units are contextualized by the `NightscoutProfileRecord` containing the profile.
    public typealias InsulinSensitivitySchedule = [ScheduleItem<Double>]

    /// A blood glucose target schedule.
    /// Schedule items are specified in <blood glucose unit>...<blood glucose unit>.
    /// Blood glucose units are contextualized by the `NightscoutProfileRecord` containing the profile.
    public typealias BloodGlucoseTargetSchedule = [ScheduleItem<ClosedRange<Double>>]

    /// The profile's carb ratio schedule.
    /// Schedule item are specified in grams per unit of insulin (g/U).
    public let carbRatioSchedule: CarbRatioSchedule

    /// The profile's basal rate schedule.
    /// Schedule items are specified in units of insulin per hour (U/hr).
    public let basalRateSchedule: BasalRateSchedule

    /// The profile's insulin sensitivity schedule.
    /// Schedule items are specified in <blood glucose unit> per unit of insulin.
    /// Blood glucose units are contextualized by the `NightscoutProfileRecord` containing this profile.
    public let sensitivitySchedule: InsulinSensitivitySchedule

    /// The profile's blood glucose target schedule.
    /// Schedule items are specified in <blood glucose unit>...<blood glucose unit>.
    /// Blood glucose units are contextualized by the `NightscoutProfileRecord` containing this profile.
    public let bloodGlucoseTargetSchedule: BloodGlucoseTargetSchedule

    /// The length of time for which insulin is active after entering the body; also known as the duration of active insulin (DIA).
    public let activeInsulinDuration: TimeInterval

    /// The rate at which carbs are absorbed during activity.
    /// Units are specified in grams per hour (g/hr).
    public let carbAbsorptionRateDuringActivity: Int

    /// A string representing the time zone for which the profile was designed.
    public let timeZone: String // TODO: use `TimeZone` here

    /// Creates a new profile.
    /// - Parameter carbRatioSchedule: The carb ratio schedule, with schedule items specified in grams per unit of insulin (g/U).
    /// - Parameter basalRateSchedule: The basal rate schedule, with schedule items specified in units of insulin per hour (U/hr).
    /// - Parameter sensitivitySchedule: The insulin sensitivity schedule, with schedule items specified in <blood glucose unit> per unit of insulin.
    /// - Parameter bloodGlucoseTargetSchedule: The blood glucose target schedule, with schedule items specified in <blood glucose unit>...<blood glucose unit>.
    /// - Parameter activeInsulinDuration: The length of time for which insulin is active after entering the body; also known as the duration of active insulin (DIA).
    /// - Parameter carbAbsorptionRateDuringActivity: The rate at which carbs are absorped during activity in grams per hour (g/hr).
    /// - Parameter timeZone: A string representing the time zone for which the profile was designed.
    public init(carbRatioSchedule: CarbRatioSchedule, basalRateSchedule: BasalRateSchedule, sensitivitySchedule: InsulinSensitivitySchedule,
                bloodGlucoseTargetSchedule: BloodGlucoseTargetSchedule, activeInsulinDuration: TimeInterval, carbAbsorptionRateDuringActivity: Int, timeZone: String) {
        self.carbRatioSchedule = carbRatioSchedule
        self.basalRateSchedule = basalRateSchedule
        self.sensitivitySchedule = sensitivitySchedule
        self.bloodGlucoseTargetSchedule = bloodGlucoseTargetSchedule
        self.activeInsulinDuration = activeInsulinDuration
        self.carbAbsorptionRateDuringActivity = carbAbsorptionRateDuringActivity
        self.timeZone = timeZone
    }
}

// MARK: - JSON

extension NightscoutProfile: JSONParseable {
    private enum Key {
        static let carbRatioSchedule: JSONKey<[JSONDictionary]> = "carbratio"
        static let basalRateSchedule: JSONKey<[JSONDictionary]> = "basal"
        static let sensitivitySchedule: JSONKey<[JSONDictionary]> = "sens"
        static let lowTargets: JSONKey<[JSONDictionary]> = "target_low"
        static let highTargets: JSONKey<[JSONDictionary]> = "target_high"
        static let activeInsulinDurationInHoursString: JSONKey<String> = "dia"
        static let carbAbsorptionRateDuringActivityString: JSONKey<String>  = "carbs_hr"
        static let timeZone: JSONKey<String>  = "timezone"
    }

    static func parse(fromJSON profileJSON: JSONDictionary) -> NightscoutProfile? {
        guard
            let carbRatioDictionaries = profileJSON[Key.carbRatioSchedule],
            let basalRateDictionaries = profileJSON[Key.basalRateSchedule],
            let sensitivityDictionaries = profileJSON[Key.sensitivitySchedule],
            let lowTargetDictionaries = profileJSON[Key.lowTargets],
            let highTargetDictionaries = profileJSON[Key.highTargets],
            let activeInsulinDurationInHours = profileJSON[Key.activeInsulinDurationInHoursString].flatMap(Double.init),
            let carbsAbsorptionRateDuringActivity = profileJSON[Key.carbAbsorptionRateDuringActivityString].flatMap(Int.init),
            let timeZone = profileJSON[Key.timeZone]
        else {
            return nil
        }

        let lowTargets: [ScheduleItem<Double>] = lowTargetDictionaries.compactMap(ScheduleItem.parse).sorted { $0.startTime < $1.startTime }
        let highTargets: [ScheduleItem<Double>] = highTargetDictionaries.compactMap(ScheduleItem.parse).sorted { $0.startTime < $1.startTime }
        var bloodGlucoseTargetSchedule: BloodGlucoseTargetSchedule = []
        for (lowTarget, highTarget) in zip(lowTargets, highTargets) {
            guard lowTarget.startTime == highTarget.startTime else {
                return nil
            }
            let targetScheduleItem = ScheduleItem(startTime: lowTarget.startTime, value: lowTarget.value...highTarget.value)
            bloodGlucoseTargetSchedule.append(targetScheduleItem)
        }

        return .init(
            carbRatioSchedule: carbRatioDictionaries.compactMap(ScheduleItem.parse(fromJSON:)),
            basalRateSchedule: basalRateDictionaries.compactMap(ScheduleItem.parse(fromJSON:)),
            sensitivitySchedule: sensitivityDictionaries.compactMap(ScheduleItem.parse(fromJSON:)),
            bloodGlucoseTargetSchedule: bloodGlucoseTargetSchedule,
            activeInsulinDuration: .hours(activeInsulinDurationInHours),
            carbAbsorptionRateDuringActivity: carbsAbsorptionRateDuringActivity,
            timeZone: timeZone
        )
    }
}

extension NightscoutProfile: JSONConvertible {
    var jsonRepresentation: JSONDictionary {
        var json: JSONDictionary = [:]
        json[Key.carbRatioSchedule] = carbRatioSchedule.jsonRepresentation
        json[Key.sensitivitySchedule] = basalRateSchedule.jsonRepresentation

        let splitTargets = bloodGlucoseTargetSchedule.map { $0.split() }
        json[Key.sensitivitySchedule] = sensitivitySchedule.jsonRepresentation
        json[Key.lowTargets] = splitTargets.map { $0.lower.jsonRepresentation }
        json[Key.highTargets] = splitTargets.map { $0.upper.jsonRepresentation }

        json[Key.activeInsulinDurationInHoursString] = String(activeInsulinDuration.hours)
        json[Key.carbAbsorptionRateDuringActivityString] = String(carbAbsorptionRateDuringActivity)
        json[Key.timeZone] = timeZone

        return json
    }
}

// can't store static properties in a generic, so we'll stick this out here instead
fileprivate enum ScheduleItemKey {
    static let startDateString: JSONKey<String> = "time"
    static let valueString: JSONKey<String> = "value"
}

extension NightscoutProfile.ScheduleItem: DataParseable, JSONParseable where Value: LosslessStringConvertible {
    static func parse(fromJSON itemJSON: JSONDictionary) -> NightscoutProfile.ScheduleItem<Value>? {
        guard
            let startTime = itemJSON[ScheduleItemKey.startDateString].flatMap(TimeFormatter.time(from:)),
            let value = itemJSON[ScheduleItemKey.valueString].flatMap(Value.init)
        else {
            return nil
        }
        
        return .init(startTime: startTime, value: value)
    }
}

extension NightscoutProfile.ScheduleItem: JSONRepresentable {
    var jsonRepresentation: JSONDictionary {
        var json: JSONDictionary = [:]
        json[ScheduleItemKey.startDateString] = TimeFormatter.string(from: startTime)
        json[ScheduleItemKey.valueString] = String(describing: value)
        return json
    }
}

extension NightscoutProfile.ScheduleItem where Value == ClosedRange<Double> {
    func split() -> (lower: NightscoutProfile.ScheduleItem<Double>, upper: NightscoutProfile.ScheduleItem<Double>) {
        let lower = NightscoutProfile.ScheduleItem(startTime: startTime, value: value.lowerBound)
        let upper = NightscoutProfile.ScheduleItem(startTime: startTime, value: value.upperBound)
        return (lower: lower, upper: upper)
    }
}

// MARK: - CustomStringConvertible

extension NightscoutProfile.ScheduleItem: CustomStringConvertible {
    public var description: String {
        return "ScheduleItem(startTime: \(TimeFormatter.prettyString(from: startTime)), value: \(value))"
    }
}

//
//  Profile.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 2/23/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Foundation


public struct Profile {
    public struct ScheduleItem<T> {
        let startTime: TimeInterval // referenced to midnight
        let value: T
    }

    public typealias CarbRatioSchedule = [ScheduleItem<Int>] // g/unit
    public typealias BasalRateSchedule = [ScheduleItem<Double>] // units/hr
    public typealias InsulinSensitivitySchedule = [ScheduleItem<Double>] // <BG unit>/unit
    public typealias BloodGlucoseTargetSchedule = [ScheduleItem<ClosedRange<Double>>] // <BG unit>...<BG unit>

    public let carbRatioSchedule: CarbRatioSchedule
    public let basalRateSchedule: BasalRateSchedule
    public let sensitivitySchedule: InsulinSensitivitySchedule
    public let bloodGlucoseTargetSchedule: BloodGlucoseTargetSchedule
    public let activeInsulinDuration: TimeInterval // DIA
    public let carbsActivityAbsorptionRate: Int // g/hour
    public let timeZone: String // TODO: use TimeZone here
}

// MARK: - JSON Parsing

extension Profile: JSONParseable {
    private enum Key {
        static let carbRatioSchedule = "carbratio"
        static let basalRateSchedule = "basal"
        static let sensitivitySchedule = "sens"
        static let lowTargets = "target_low"
        static let highTargets = "target_high"
        static let activeInsulinDuration = "dia"
        static let carbsActivityAbsorptionRate = "carbs_hr"
        static let timeZone = "timezone"
    }

    static func parse(from profileJSON: JSONDictionary) -> Profile? {
        guard
            let carbRatioDictionaries = profileJSON[Key.carbRatioSchedule] as? [JSONDictionary],
            let basalRateDictionaries = profileJSON[Key.basalRateSchedule] as? [JSONDictionary],
            let sensitivityDictionaries = profileJSON[Key.sensitivitySchedule] as? [JSONDictionary],
            let lowTargetDictionaries = profileJSON[Key.lowTargets] as? [JSONDictionary],
            let highTargetDictionaries = profileJSON[Key.highTargets] as? [JSONDictionary],
            let activeInsulinDurationString = profileJSON[Key.activeInsulinDuration] as? String,
            let activeInsulinDurationInHours = Double(activeInsulinDurationString),
            let carbsActivityAbsorptionRateString = profileJSON[Key.carbsActivityAbsorptionRate] as? String,
            let carbsActivityAbsorptionRate = Int(carbsActivityAbsorptionRateString),
            let timeZone = profileJSON[Key.timeZone] as? String
        else {
            return nil
        }

        let lowTargets: [ScheduleItem<Double>] = lowTargetDictionaries.flatMap(ScheduleItem.parse).sorted { $0.startTime < $1.startTime }
        let highTargets: [ScheduleItem<Double>] = highTargetDictionaries.flatMap(ScheduleItem.parse).sorted { $0.startTime < $1.startTime }
        var bloodGlucoseTargetSchedule: BloodGlucoseTargetSchedule = []
        for (lowTarget, highTarget) in zip(lowTargets, highTargets) {
            guard lowTarget.startTime == highTarget.startTime else {
                return nil
            }
            let targetScheduleItem = ScheduleItem(startTime: lowTarget.startTime, value: lowTarget.value...highTarget.value)
            bloodGlucoseTargetSchedule.append(targetScheduleItem)
        }

        return Profile(
            carbRatioSchedule: carbRatioDictionaries.flatMap(ScheduleItem.parse),
            basalRateSchedule: basalRateDictionaries.flatMap(ScheduleItem.parse),
            sensitivitySchedule: sensitivityDictionaries.flatMap(ScheduleItem.parse),
            bloodGlucoseTargetSchedule: bloodGlucoseTargetSchedule,
            activeInsulinDuration: .hours(activeInsulinDurationInHours),
            carbsActivityAbsorptionRate: carbsActivityAbsorptionRate,
            timeZone: timeZone
        )
    }
}

// can't store static properties in a generic, so we'll stick this out here instead
fileprivate enum ScheduleItemKey {
    static let startDateString = "time"
    static let valueString = "value"
}

// TODO: conditional conformance here
extension Profile.ScheduleItem /*: JSONParseable */ where T: StringParseable {
    static func parse(from itemJSON: JSONDictionary) -> Profile.ScheduleItem<T>? {
        guard
            let startDateString = itemJSON[ScheduleItemKey.startDateString] as? String,
            let startTime = TimeFormatter.time(from: startDateString),
            let valueString = itemJSON[ScheduleItemKey.valueString] as? String,
            let value = T(valueString)
        else {
            return nil
        }
        
        return Profile.ScheduleItem(startTime: startTime, value: value)
    }
}

// MARK: - CustomStringConvertible

extension Profile.ScheduleItem: CustomStringConvertible {
    public var description: String {
        return "ScheduleItem(startTime: \(TimeFormatter.string(from: startTime)), value: \(value))"
    }
}

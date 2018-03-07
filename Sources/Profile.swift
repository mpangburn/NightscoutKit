//
//  Profile.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 2/23/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Foundation


public struct Profile {
    public struct ScheduleItem<Value> {
        let startTime: TimeInterval // referenced to midnight
        let value: Value
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
    typealias JSONParseType = JSONDictionary

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

    static func parse(fromJSON profileJSON: JSONDictionary) -> Profile? {
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

extension Profile: JSONConvertible {
    func json() -> JSONDictionary {
        let splitTargets = bloodGlucoseTargetSchedule.map { $0.split() }
        return [
            Key.carbRatioSchedule: carbRatioSchedule.map { $0.json() },
            Key.basalRateSchedule: basalRateSchedule.map { $0.json() },
            Key.sensitivitySchedule: sensitivitySchedule.map { $0.json() },
            Key.lowTargets: splitTargets.map { $0.lower.json() },
            Key.highTargets: splitTargets.map { $0.upper.json() },
            Key.activeInsulinDuration: String(activeInsulinDuration.hours),
            Key.carbsActivityAbsorptionRate: String(carbsActivityAbsorptionRate),
            Key.timeZone: timeZone
        ]
    }
}

// can't store static properties in a generic, so we'll stick this out here instead
fileprivate enum ScheduleItemKey {
    static let startDateString = "time"
    static let valueString = "value"
}

// TODO: conditional conformance here
extension Profile.ScheduleItem /*: JSONParseable */ where Value: StringParseable {
    static func parse(from itemJSON: JSONDictionary) -> Profile.ScheduleItem<Value>? {
        guard
            let startDateString = itemJSON[ScheduleItemKey.startDateString] as? String,
            let startTime = TimeFormatter.time(from: startDateString),
            let valueString = itemJSON[ScheduleItemKey.valueString] as? String,
            let value = Value(valueString)
        else {
            return nil
        }
        
        return Profile.ScheduleItem(startTime: startTime, value: value)
    }
}

extension Profile.ScheduleItem /*: JSONConvertible */ /* where T: StringParseable */ {
    func json() -> JSONDictionary {
        return [
            ScheduleItemKey.startDateString: TimeFormatter.string(from: startTime),
            ScheduleItemKey.valueString: String(describing: value)
        ]
    }
}

extension Profile.ScheduleItem where Value == ClosedRange<Double> {
    func split() -> (lower: Profile.ScheduleItem<Double>, upper: Profile.ScheduleItem<Double>) {
        let lower = Profile.ScheduleItem(startTime: startTime, value: value.lowerBound)
        let upper = Profile.ScheduleItem(startTime: startTime, value: value.upperBound)
        return (lower: lower, upper: upper)
    }
}

// MARK: - CustomStringConvertible

extension Profile.ScheduleItem: CustomStringConvertible {
    public var description: String {
        return "ScheduleItem(startTime: \(TimeFormatter.prettyString(from: startTime)), value: \(value))"
    }
}

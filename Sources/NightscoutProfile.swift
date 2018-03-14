//
//  NightscoutProfile.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 2/23/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

public struct NightscoutProfile {
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

// MARK: - JSON

extension NightscoutProfile: JSONParseable {
    typealias JSONParseType = JSONDictionary

    private enum Key {
        static let carbRatioSchedule: JSONKey<[JSONDictionary]> = "carbratio"
        static let basalRateSchedule: JSONKey<[JSONDictionary]> = "basal"
        static let sensitivitySchedule: JSONKey<[JSONDictionary]> = "sens"
        static let lowTargets: JSONKey<[JSONDictionary]> = "target_low"
        static let highTargets: JSONKey<[JSONDictionary]> = "target_high"
        static let activeInsulinDurationInHoursString: JSONKey<String> = "dia"
        static let carbsActivityAbsorptionRateString: JSONKey<String>  = "carbs_hr"
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
            let carbsActivityAbsorptionRate = profileJSON[Key.carbsActivityAbsorptionRateString].flatMap(Int.init),
            let timeZone = profileJSON[Key.timeZone]
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

        // TODO: minor JSON parsing cleanup in this file once ScheduleItem can conditionally conform to JSONParseable/JSONConvertible
        return NightscoutProfile(
            carbRatioSchedule: carbRatioDictionaries.flatMap(ScheduleItem.parse(fromJSON:)),
            basalRateSchedule: basalRateDictionaries.flatMap(ScheduleItem.parse(fromJSON:)),
            sensitivitySchedule: sensitivityDictionaries.flatMap(ScheduleItem.parse(fromJSON:)),
            bloodGlucoseTargetSchedule: bloodGlucoseTargetSchedule,
            activeInsulinDuration: .hours(activeInsulinDurationInHours),
            carbsActivityAbsorptionRate: carbsActivityAbsorptionRate,
            timeZone: timeZone
        )
    }
}

extension NightscoutProfile: JSONConvertible {
    var jsonRepresentation: JSONDictionary {
        var json: JSONDictionary = [:]
        json[Key.carbRatioSchedule] = carbRatioSchedule.map { $0.jsonRepresentation }
        json[Key.sensitivitySchedule] = basalRateSchedule.map { $0.jsonRepresentation }

        let splitTargets = bloodGlucoseTargetSchedule.map { $0.split() }
        json[Key.sensitivitySchedule] = sensitivitySchedule.map { $0.jsonRepresentation }
        json[Key.lowTargets] = splitTargets.map { $0.lower.jsonRepresentation }
        json[Key.highTargets] = splitTargets.map { $0.upper.jsonRepresentation }

        json[Key.activeInsulinDurationInHoursString] = String(activeInsulinDuration.hours)
        json[Key.carbsActivityAbsorptionRateString] = String(carbsActivityAbsorptionRate)
        json[Key.timeZone] = timeZone

        return json
    }
}

// can't store static properties in a generic, so we'll stick this out here instead
fileprivate enum ScheduleItemKey {
    static let startDateString: JSONKey<String> = "time"
    static let valueString: JSONKey<String> = "value"
}

// TODO: conditional conformance here
extension NightscoutProfile.ScheduleItem /*: JSONParseable */ where Value: LosslessStringConvertible {
    static func parse(fromJSON itemJSON: JSONDictionary) -> NightscoutProfile.ScheduleItem<Value>? {
        guard
            let startTime = itemJSON[ScheduleItemKey.startDateString].flatMap(TimeFormatter.time(from:)),
            let value = itemJSON[ScheduleItemKey.valueString].flatMap(Value.init)
        else {
            return nil
        }
        
        return NightscoutProfile.ScheduleItem(startTime: startTime, value: value)
    }
}

extension NightscoutProfile.ScheduleItem /*: JSONConvertible */ /* where T: StringParseable */ {
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

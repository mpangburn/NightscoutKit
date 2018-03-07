//
//  NightscoutTreatment.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 2/16/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Foundation


public struct NightscoutTreatment: UniquelyIdentifiable {
    public enum EventType {
        case bloodGlucoseCheck
        case bolus(type: BolusType)
        case tempBasal(type: TempBasalType)
        case carbCorrection
        case announcement, note, question
        case exercise
        case suspendPump, resumePump
        case pumpSiteChange, insulinChange
        case sensorStart, sensorChange
        case profileSwitch(profileName: String)
        case diabeticAlertDogAlert
        case none
        case unknown(String)
    }

    public enum BolusType {
        case snack
        case meal
        case correction
        case combo(totalInsulin: Double, percentageUpFront: Int)
    }

    public enum TempBasalType {
        case percentage(Int)
        case absolute(rate: Double)
        case ended
    }

    public enum GlucoseSource: String {
        case meter = "Finger"
        case sensor = "Sensor"
    }

    public struct GlucoseMeasurement {
        public let value: Double
        public let units: BloodGlucoseUnit
        public let source: GlucoseSource
    }

    public let id: String
    public let eventType: EventType
    public let date: Date
    public let duration: TimeInterval
    public let glucose: GlucoseMeasurement?
    public let insulinGiven: Double? // units
    public let carbsConsumed: Int? // grams
    public let creator: String
    public let notes: String
}

// MARK: - Equatable

extension NightscoutTreatment.GlucoseMeasurement: Equatable {
    public static func == (lhs: NightscoutTreatment.GlucoseMeasurement, rhs: NightscoutTreatment.GlucoseMeasurement) -> Bool {
        return lhs.value == rhs.value
            && lhs.units == rhs.units
            && lhs.source == rhs.source
    }
}

// MARK: - JSON Parsing

extension NightscoutTreatment: JSONParseable {
    typealias JSONParseType = JSONDictionary

    enum Key {
        static let id = "_id"
        static let eventType = "eventType"
        static let dateString = "created_at"
        static let duration = "duration"
        static let glucoseValue = "glucose"
        static let unitString = "units"
        static let glucoseSourceString = "glucoseType"
        static let insulinGiven = "insulin"
        static let carbsConsumed = "carbs"
        static let creator = "enteredBy"
        static let notes = "notes"
    }

    static func parse(fromJSON treatmentJSON: JSONDictionary) -> NightscoutTreatment? {
        guard
            let id = treatmentJSON[Key.id] as? String,
            let eventType = EventType.parse(fromJSON: treatmentJSON),
            let dateString = treatmentJSON[Key.dateString] as? String,
            let date = TimeFormatter.date(from: dateString)
        else {
            return nil
        }

        let glucose: GlucoseMeasurement?
        if let glucoseValue = treatmentJSON[Key.glucoseValue] as? Double,
            let unitString = treatmentJSON[Key.unitString] as? String,
            let units = BloodGlucoseUnit(rawValue: unitString),
            let glucoseSourceString = treatmentJSON[Key.glucoseSourceString] as? String,
            let glucoseSource = GlucoseSource(rawValue: glucoseSourceString) {
                glucose = GlucoseMeasurement(value: glucoseValue, units: units, source: glucoseSource)
        } else {
            glucose = nil
        }

        return NightscoutTreatment(
            id: id,
            eventType: eventType,
            date: date,
            duration: .minutes((treatmentJSON[Key.duration] as? Double) ?? 0),
            glucose: glucose,
            insulinGiven: treatmentJSON[Key.insulinGiven] as? Double,
            carbsConsumed: treatmentJSON[Key.carbsConsumed] as? Int,
            creator: (treatmentJSON[Key.creator] as? String) ?? "",
            notes: (treatmentJSON[Key.notes] as? String) ?? ""
        )
    }
}

extension NightscoutTreatment: JSONConvertible {
    func json() -> JSONDictionary {
        var raw: RawValue = [
            Key.id: id,
            Key.eventType: eventType.simpleRawValue,
            Key.duration: duration.minutes,
            Key.dateString: TimeFormatter.string(from: date),
            Key.creator: creator,
            Key.notes: notes
        ]

        switch eventType {
        case .bolus(type: .combo(totalInsulin: let totalInsulin, percentageUpFront: let percentageUpFront)):
            raw[BolusType.Key.totalInsulinString] = String(totalInsulin)
            raw[BolusType.Key.percentageUpFrontString] = String(percentageUpFront)
            raw[BolusType.Key.percentageOverTimeString] = String(100 - percentageUpFront)
        case .tempBasal(type: let type):
            switch type {
            case .percentage(let percentage):
                raw[TempBasalType.Key.percentage] = percentage
            case .absolute(rate: let rate):
                raw[TempBasalType.Key.absolute] = rate
            case .ended:
                break
            }
        case .profileSwitch(profileName: let profileName):
            raw[EventType.Key.profileName] = profileName
        case .announcement:
            raw["isAnnouncement"] = 1
        default:
            break
        }

        if let glucose = glucose {
            raw[Key.glucoseValue] = glucose.value
            raw[Key.unitString] = glucose.units.rawValue
            raw[Key.glucoseSourceString] = glucose.source.rawValue
        }

        raw[Key.carbsConsumed] = carbsConsumed
        raw[Key.insulinGiven] = insulinGiven

        return raw
    }
}

extension NightscoutTreatment.EventType: JSONParseable {
    typealias JSONParseType = JSONDictionary

    fileprivate enum Key {
        static let profileName = "profile"
    }

    static func parse(fromJSON treatmentJSON: JSONDictionary) -> NightscoutTreatment.EventType? {
        guard let eventTypeString = treatmentJSON[NightscoutTreatment.Key.eventType] as? String else {
            return nil
        }

        if let simpleEventType = NightscoutTreatment.EventType(simpleRawValue: eventTypeString) {
            return simpleEventType
        } else if let bolusType = NightscoutTreatment.BolusType.parse(fromJSON: treatmentJSON) {
            return .bolus(type: bolusType)
        } else if let tempBasalType = NightscoutTreatment.TempBasalType.parse(fromJSON: treatmentJSON) {
            return .tempBasal(type: tempBasalType)
        } else if eventTypeString == "Profile Switch" {
            guard let profileName = treatmentJSON[Key.profileName] as? String else {
                return nil
            }
            return .profileSwitch(profileName: profileName)
        } else {
            return .unknown(eventTypeString)
        }
    }
}

extension NightscoutTreatment.EventType: PartiallyRawRepresentable {
    static var simpleCases: [NightscoutTreatment.EventType] {
        return [
            .bloodGlucoseCheck, .carbCorrection, .announcement, .note, .question,
            .exercise, .suspendPump, .resumePump, .pumpSiteChange, .insulinChange,
            .sensorStart, .sensorChange, .diabeticAlertDogAlert, .none
        ]
    }

    var simpleRawValue: String {
        switch self {
        case .bloodGlucoseCheck:
            return "BG Check"
        case .bolus(type: let type):
            return type.simpleRawValue
        case .tempBasal(type: _):
            return "Temp Basal"
        case .carbCorrection:
            return "Carb Correction"
        case .announcement:
            return "Announcement"
        case .note:
            return "Note"
        case .question:
            return "Question"
        case .exercise:
            return "Exercise"
        case .suspendPump:
            return "Suspend Pump"
        case .resumePump:
            return "Resume Pump"
        case .pumpSiteChange:
            return "Site Change"
        case .insulinChange:
            return "Insulin Change"
        case .sensorStart:
            return "Sensor Start"
        case .sensorChange:
            return "Sensor Change"
        case .profileSwitch(profileName: _):
            return "Profile Switch"
        case .diabeticAlertDogAlert:
            return "D.A.D. Alert"
        case .none:
            return "<none>"
        case .unknown(let description):
            return description
        }
    }
}

extension NightscoutTreatment.BolusType: JSONParseable {
    typealias JSONParseType = JSONDictionary

    fileprivate enum Key {
        static let totalInsulinString = "enteredinsulin"
        static let percentageUpFrontString = "splitNow"
        static let percentageOverTimeString = "splitExt"
    }

    static func parse(fromJSON treatmentJSON: JSONDictionary) -> NightscoutTreatment.BolusType? {
        guard let eventTypeString = treatmentJSON[NightscoutTreatment.Key.eventType] as? String, eventTypeString.contains("Bolus") else {
            return nil
        }

        if let simpleBolusType = NightscoutTreatment.BolusType(simpleRawValue: eventTypeString) {
            return simpleBolusType
        } else {
            guard
                let totalInsulinString = treatmentJSON[Key.totalInsulinString] as? String,
                let totalInsulin = Double(totalInsulinString),
                let percentageUpFrontString = treatmentJSON[Key.percentageUpFrontString] as? String,
                let percentageUpFront = Int(percentageUpFrontString)
            else {
                return nil
            }
            return .combo(totalInsulin: totalInsulin, percentageUpFront: percentageUpFront)
        }
    }
}

extension NightscoutTreatment.BolusType: PartiallyRawRepresentable {
    static var simpleCases: [NightscoutTreatment.BolusType] {
        return [.snack, .meal, .correction]
    }

    var simpleRawValue: String {
        let typeString: String
        switch self {
        case .snack:
            typeString = "Snack"
        case .meal:
            typeString = "Meal"
        case .correction:
            typeString = "Correction"
        case .combo(totalInsulin: _, percentageUpFront: _):
            typeString = "Combo"
        }

        return "\(typeString) Bolus"
    }
}

extension NightscoutTreatment.TempBasalType: JSONParseable {
    typealias JSONParseType = JSONDictionary

    fileprivate enum Key {
        static let percentage = "percent"
        static let absolute = "absolute"
    }

    static func parse(fromJSON treatmentJSON: JSONDictionary) -> NightscoutTreatment.TempBasalType? {
        guard let eventTypeString = treatmentJSON[NightscoutTreatment.Key.eventType] as? String, eventTypeString == "Temp Basal" else {
            return nil
        }

        if let percentage = treatmentJSON[Key.percentage] as? Int {
            return .percentage(percentage)
        } else if let rate = treatmentJSON[Key.absolute] as? Double {
            return .absolute(rate: rate)
        } else {
            return .ended
        }
    }
}

// MARK: - CustomStringConvertible

extension NightscoutTreatment.EventType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .bolus(type: let type):
            return type.description
        case .tempBasal(type: let type):
            return type.description
        case .profileSwitch(profileName: let profileName):
            return "Profile Switch (\(profileName))"
        case .unknown(let eventString):
            return "\(eventString) (Unknown)"
        default: // simple case
            return simpleRawValue
        }
    }
}

extension NightscoutTreatment.BolusType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .combo(totalInsulin: let totalInsulin, percentageUpFront: let percentageUpFront):
            return "Combo Bolus (\(totalInsulin)U, \(percentageUpFront)/\(100 - percentageUpFront))"
        case .snack, .meal, .correction:
            return simpleRawValue
        }
    }
}

extension NightscoutTreatment.TempBasalType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .percentage(let percentage):
            return "Temp Basal (\(percentage)%)"
        case .absolute(rate: let rate):
            return "Temp Basal (\(rate)U)"
        case .ended:
            return "Temp Basal Ended"
        }
    }
}

//
//  Treatment.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 2/16/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Foundation


struct Treatment: UniquelyIdentifiable {
    enum EventType {
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
        case unknown(String)
    }

    enum BolusType {
        case snack
        case meal
        case correction
        case combo(totalInsulin: Double, percentageUpFront: Int)
    }

    enum TempBasalType {
        case percentage(Int)
        case absolute(rate: Double)
        case ended
    }

    enum GlucoseSource: String {
        case meter = "Finger"
        case sensor = "Sensor"
    }

    typealias GlucoseMeasurement = (value: Double, units: BloodGlucoseUnit, source: GlucoseSource)

    let id: String
    let eventType: EventType
    let date: Date
    let duration: TimeInterval
    let glucose: GlucoseMeasurement?
    let insulinGiven: Double? // units
    let carbsConsumed: Int? // grams
    let creator: String
    let notes: String
}

extension Treatment: JSONParseable {
    fileprivate struct Key {
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

    static func parse(from treatmentJSON: JSONDictionary) -> Treatment? {
        guard
            let id = treatmentJSON[Key.id] as? String,
            let eventType = EventType.parse(from: treatmentJSON),
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
                glucose = (value: glucoseValue, units: units, source: glucoseSource)
        } else {
            glucose = nil
        }

        return Treatment(
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

extension Treatment: JSONConvertible {
    var rawValue: JSONDictionary {
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

        if let (glucoseValue, units, glucoseSource) = glucose {
            raw[Key.glucoseValue] = glucoseValue
            raw[Key.unitString] = units.rawValue
            raw[Key.glucoseSourceString] = glucoseSource.rawValue
        }

        raw[Key.carbsConsumed] = carbsConsumed
        raw[Key.insulinGiven] = insulinGiven

        return raw
    }
}

extension Treatment.EventType: JSONParseable {
    fileprivate struct Key {
        static let profileName = "profile"
    }

    static func parse(from treatmentJSON: JSONDictionary) -> Treatment.EventType? {
        guard let eventTypeString = treatmentJSON[Treatment.Key.eventType] as? String else {
            return nil
        }

        if let simpleEventType = Treatment.EventType(simpleRawValue: eventTypeString) {
            return simpleEventType
        } else if let bolusType = Treatment.BolusType.parse(from: treatmentJSON) {
            return .bolus(type: bolusType)
        } else if let tempBasalType = Treatment.TempBasalType.parse(from: treatmentJSON) {
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

extension Treatment.EventType: PartiallyRawRepresentable {
    static var simpleCases: [Treatment.EventType] {
        return [
            .bloodGlucoseCheck, .carbCorrection, .announcement, .note, .question,
            .exercise, .suspendPump, .resumePump, .pumpSiteChange,
            .insulinChange, .sensorStart, .sensorChange, .diabeticAlertDogAlert
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
        case .announcement, .note, .question, .exercise:
            return String(describing: self).capitalized
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
        case .unknown(let description):
            return description
        }
    }
}

extension Treatment.BolusType: JSONParseable {
    fileprivate struct Key {
        static let totalInsulinString = "enteredinsulin"
        static let percentageUpFrontString = "splitNow"
        static let percentageOverTimeString = "splitExt"
    }

    static func parse(from treatmentJSON: JSONDictionary) -> Treatment.BolusType? {
        guard let eventTypeString = treatmentJSON[Treatment.Key.eventType] as? String, eventTypeString.contains("Bolus") else {
            return nil
        }

        if let simpleBolusType = Treatment.BolusType(simpleRawValue: eventTypeString) {
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

extension Treatment.BolusType: PartiallyRawRepresentable {
    static var simpleCases: [Treatment.BolusType] {
        return [.snack, .meal, .correction]
    }

    var simpleRawValue: String {
        let typeString: String
        switch self {
        case .snack, .meal, .correction:
            typeString = String(describing: self).capitalized
        case .combo(totalInsulin: _, percentageUpFront: _):
            typeString = "Combo"
        }

        return "\(typeString) Bolus"
    }
}

extension Treatment.TempBasalType: JSONParseable {
    fileprivate struct Key {
        static let percentage = "percent"
        static let absolute = "absolute"
    }

    static func parse(from treatmentJSON: JSONDictionary) -> Treatment.TempBasalType? {
        guard let eventTypeString = treatmentJSON[Treatment.Key.eventType] as? String, eventTypeString == "Temp Basal" else {
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

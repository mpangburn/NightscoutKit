//
//  NightscoutTreatment.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 2/16/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

public struct NightscoutTreatment: UniquelyIdentifiable {
    public enum EventType {
        case bloodGlucoseCheck
        case bolus(type: BolusType)
        case temporaryBasal(type: TemporaryBasalType)
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

    public enum TemporaryBasalType {
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
    public let creator: String?
    public let notes: String?

    public init(eventType: EventType, date: Date, duration: TimeInterval, glucose: GlucoseMeasurement?, insulinGiven: Double?, carbsConsumed: Int?, creator: String?, notes: String?) {
        self.init(
            id: IdentifierFactory.makeID(),
            eventType: eventType,
            date: date,
            duration: duration,
            glucose: glucose,
            insulinGiven: insulinGiven,
            carbsConsumed: carbsConsumed,
            creator: creator,
            notes: notes
        )
    }

    init(id: String, eventType: EventType, date: Date, duration: TimeInterval, glucose: GlucoseMeasurement?, insulinGiven: Double?, carbsConsumed: Int?, creator: String?, notes: String?) {
        self.id = id
        self.eventType = eventType
        self.date = date
        self.duration = duration
        self.glucose = glucose
        self.insulinGiven = insulinGiven
        self.carbsConsumed = carbsConsumed
        self.creator = creator
        self.notes = notes
    }
}

// MARK: - Equatable

extension NightscoutTreatment.GlucoseMeasurement: Equatable {
    public static func == (lhs: NightscoutTreatment.GlucoseMeasurement, rhs: NightscoutTreatment.GlucoseMeasurement) -> Bool {
        return lhs.value == rhs.value
            && lhs.units == rhs.units
            && lhs.source == rhs.source
    }
}

// MARK: - JSON

extension NightscoutTreatment: JSONParseable {
    typealias JSONParseType = JSONDictionary

    enum Key {
        static let id: JSONKey<String> = "_id"
        static let eventTypeString: JSONKey<String> = "eventType"
        static let dateString: JSONKey<String> = "created_at"
        static let duration: JSONKey<Double> = "duration"
        static let glucoseValue: JSONKey<Double> = "glucose"
        static let units: JSONKey<BloodGlucoseUnit> = "units"
        static let glucoseSource: JSONKey<GlucoseSource> = "glucoseType"
        static let insulinGiven: JSONKey<Double> = "insulin"
        static let carbsConsumed: JSONKey<Int> = "carbs"
        static let creator: JSONKey<String> = "enteredBy"
        static let notes: JSONKey<String> = "notes"
    }

    static func parse(fromJSON treatmentJSON: JSONDictionary) -> NightscoutTreatment? {
        guard
            let id = treatmentJSON[Key.id],
            let eventType = EventType.parse(fromJSON: treatmentJSON),
            let date = treatmentJSON[convertingDateFrom: Key.dateString]
        else {
            return nil
        }

        let glucose: GlucoseMeasurement?
        if let glucoseValue = treatmentJSON[Key.glucoseValue],
            let units = treatmentJSON[convertingFrom: Key.units],
            let glucoseSource = treatmentJSON[convertingFrom: Key.glucoseSource] {
                glucose = GlucoseMeasurement(value: glucoseValue, units: units, source: glucoseSource)
        } else {
            glucose = nil
        }

        return NightscoutTreatment(
            id: id,
            eventType: eventType,
            date: date,
            duration: .minutes(treatmentJSON[Key.duration] ?? 0),
            glucose: glucose,
            insulinGiven: treatmentJSON[Key.insulinGiven],
            carbsConsumed: treatmentJSON[Key.carbsConsumed],
            creator: treatmentJSON[Key.creator],
            notes: treatmentJSON[Key.notes]
        )
    }
}

extension NightscoutTreatment: JSONConvertible {
    var jsonRepresentation: JSONDictionary {
        var json: JSONDictionary = [:]

        json[Key.id] = id
        json[Key.eventTypeString] = eventType.simpleRawValue
        json[Key.duration] = duration.minutes
        json[convertingDateFrom: Key.dateString] = date
        json[Key.creator] = creator
        json[Key.notes] = notes

        switch eventType {
        case .bolus(type: .combo(totalInsulin: let totalInsulin, percentageUpFront: let percentageUpFront)):
            json[BolusType.Key.totalInsulinString] = String(totalInsulin)
            json[BolusType.Key.percentageUpFrontString] = String(percentageUpFront)
            json[BolusType.Key.percentageOverTimeString] = String(100 - percentageUpFront)
        case .temporaryBasal(type: let type):
            switch type {
            case .percentage(let percentage):
                json[TemporaryBasalType.Key.percentage] = percentage
            case .absolute(rate: let rate):
                json[TemporaryBasalType.Key.absolute] = rate
            case .ended:
                break
            }
        case .profileSwitch(profileName: let profileName):
            json[EventType.Key.profileName] = profileName
        case .announcement:
            json["isAnnouncement"] = 1
        default:
            break
        }

        if let glucose = glucose {
            json[Key.glucoseValue] = glucose.value
            json[convertingFrom: Key.units] = glucose.units
            json[convertingFrom: Key.glucoseSource] = glucose.source
        }

        json[Key.carbsConsumed] = carbsConsumed
        json[Key.insulinGiven] = insulinGiven

        return json
    }
}

extension NightscoutTreatment.EventType: JSONParseable {
    typealias JSONParseType = JSONDictionary

    fileprivate enum Key {
        static let profileName: JSONKey<String> = "profile"
    }

    static func parse(fromJSON treatmentJSON: JSONDictionary) -> NightscoutTreatment.EventType? {
        guard let eventTypeString = treatmentJSON[NightscoutTreatment.Key.eventTypeString] else {
            return nil
        }

        if let simpleEventType = NightscoutTreatment.EventType(simpleRawValue: eventTypeString) {
            return simpleEventType
        } else if let bolusType = NightscoutTreatment.BolusType.parse(fromJSON: treatmentJSON) {
            return .bolus(type: bolusType)
        } else if let tempBasalType = NightscoutTreatment.TemporaryBasalType.parse(fromJSON: treatmentJSON) {
            return .temporaryBasal(type: tempBasalType)
        } else if eventTypeString == "Profile Switch" {
            guard let profileName = treatmentJSON[Key.profileName] else {
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
        case .temporaryBasal(type: _):
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
        static let totalInsulinString: JSONKey<String> = "enteredinsulin"
        static let percentageUpFrontString: JSONKey<String> = "splitNow"
        static let percentageOverTimeString: JSONKey<String> = "splitExt"
    }

    static func parse(fromJSON treatmentJSON: JSONDictionary) -> NightscoutTreatment.BolusType? {
        guard let eventTypeString = treatmentJSON[NightscoutTreatment.Key.eventTypeString], eventTypeString.contains("Bolus") else {
            return nil
        }

        if let simpleBolusType = NightscoutTreatment.BolusType(simpleRawValue: eventTypeString) {
            return simpleBolusType
        } else {
            guard
                let totalInsulinString = treatmentJSON[Key.totalInsulinString],
                let totalInsulin = Double(totalInsulinString),
                let percentageUpFrontString = treatmentJSON[Key.percentageUpFrontString],
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

extension NightscoutTreatment.TemporaryBasalType: JSONParseable {
    typealias JSONParseType = JSONDictionary

    fileprivate enum Key {
        static let percentage = "percent"
        static let absolute = "absolute"
    }

    static func parse(fromJSON treatmentJSON: JSONDictionary) -> NightscoutTreatment.TemporaryBasalType? {
        guard let eventTypeString = treatmentJSON[NightscoutTreatment.Key.eventTypeString], eventTypeString == "Temp Basal" else {
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
        case .temporaryBasal(type: let type):
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

extension NightscoutTreatment.TemporaryBasalType: CustomStringConvertible {
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

//
//  NightscoutTreatment.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 2/16/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Foundation


/// A Nightscout treatment.
/// This type stores the event type and its details.
public struct NightscoutTreatment: NightscoutIdentifiable, TimelineValue, BloodGlucoseUnitConvertible {
    /// An event type describing a treatment.
    public enum EventType: Hashable {
        case bloodGlucoseCheck(GlucoseMeasurement)
        case bolus(BolusEvent)
        case temporaryBasal(TemporaryBasalEvent)
        case carbCorrection(grams: Int)
        case announcement(String)
        case note(NoteEvent)
        case question(String)
        case exercise(ExerciseEvent)
        case suspendPump, resumePump
        case pumpSiteChange, insulinChange
        case sensorStart, sensorChange
        case profileSwitch(ProfileSwitchEvent)
        case diabeticAlertDogAlert
        case none
        case unknown(String)
    }

    /// A glucose measurement.
    /// This type contains the glucose value, units of measurement, and source.
    public struct GlucoseMeasurement: Hashable, BloodGlucoseUnitConvertible {
        /// The source of a glucose measurement—meter or sensor.
        public enum Source: String {
            case meter = "Finger"
            case sensor = "Sensor"
        }

        /// The glucose value and the units in which it is measured.
        public let glucoseValue: BloodGlucoseValue

        /// The source of the measurement.
        public let source: Source

        /// Creates a new glucose measurement.
        /// - Parameter glucoseValue: The measured glucose value.
        /// - Parameter source: The source of the measurement.
        /// - Returns: A new glucose measurement.
        public init(glucoseValue: BloodGlucoseValue, source: Source) {
            self.glucoseValue = glucoseValue
            self.source = source
        }

        /// Returns a glucose measurement converted to the specified blood glucose units.
        /// - Parameter units: The blood glucose units to which to convert.
        /// - Returns: An glucose measurement converted to the specified blood glucose units.
        public func converted(to units: BloodGlucoseUnit) -> GlucoseMeasurement {
            return GlucoseMeasurement(glucoseValue: glucoseValue.converted(to: units), source: source)
        }
    }

    /// The treatment's unique, internally assigned identifier.
    public let id: NightscoutIdentifier

    /// The event type describing the treatment.
    public let eventType: EventType

    /// The date at which the treatment occurred.
    public let date: Date

    /// The glucose measurement at the time of the treatment.
    public let glucose: GlucoseMeasurement?

    /// The insulin given at the time of the treatment in units (U).
    public let insulinGiven: Double?

    /// The carbs consumed at the time of the treatment in grams (g).
    public let carbsConsumed: Int?

    /// The name of the individual who entered the treatment.
    public let recorder: String?

    /// The notes entered with the treatment.
    public let notes: String?

    /// The duration of the treatment.
    /// This property is `nil` if the treatment's event type does not represent a timeline period.
    public var duration: TimeInterval? {
        switch eventType {
        case .bolus(.combo(let event)):
            return event.duration
        case .temporaryBasal(.began(let event)):
            return event.duration
        case .note(let event):
            return event.duration
        case .exercise(let event):
            return event.duration
        case .profileSwitch(let event):
            return event.duration
        default:
            return nil
        }
    }

    /// Creates a new treatment.
    /// - Parameter id: The treatment identifier. By default, a new identifier is generated.
    /// - Parameter eventType: The event type describing the treatment.
    /// - Parameter date: The date at which the treatment occurred.
    /// - Parameter duration: The duration of the treatment.
    /// - Parameter glucose: The glucose measurement at the time of the treatment.
    /// - Parameter insulinGiven: The insulin given at the time of the treatment in units (U).
    /// - Parameter carbsConsumed: The carbs consumed at the time of the treatment in grams (g).
    /// - Parameter recorder: The name of the individual who entered the treatment.
    /// - Parameter notes: The notes entered with the treatment.
    /// - Returns: A new treatment.
    public init(id: NightscoutIdentifier = .init(), eventType: EventType, date: Date, glucose: GlucoseMeasurement?,
                insulinGiven: Double?, carbsConsumed: Int?, recorder: String?, notes: String?) {
        self.id = id
        self.eventType = eventType
        self.date = date
        self.glucose = glucose
        self.insulinGiven = insulinGiven
        self.carbsConsumed = carbsConsumed
        self.recorder = recorder
        self.notes = notes
    }

    /// Returns a treatment with its glucose value converted to the specified blood glucose units.
    /// - Parameter units: The blood glucose units to which to convert.
    /// - Returns: A treatment with its glucose value converted to the specified blood glucose units.
    public func converted(to units: BloodGlucoseUnit) -> NightscoutTreatment {
        return NightscoutTreatment(
            id: id,
            eventType: eventType.converted(to: units),
            date: date,
            glucose: glucose?.converted(to: units),
            insulinGiven: insulinGiven,
            carbsConsumed: carbsConsumed,
            recorder: recorder,
            notes: notes
        )
    }
}

extension NightscoutTreatment.EventType: BloodGlucoseUnitConvertible {
    /// Returns the event type with its glucose value converted to the specified blood glucose units.
    /// If the event type is not `.bloodGlucoseCheck`, this function returns the event type unmodified.
    /// - Parameter units: The blood glucose units to which to convert.
    /// - Returns: The event type with its glucose value converted to the specified blood glucose units.
    public func converted(to units: BloodGlucoseUnit) -> NightscoutTreatment.EventType {
        switch self {
        case .bloodGlucoseCheck(let glucose):
            return .bloodGlucoseCheck(glucose.converted(to: units))
        default:
            return self
        }
    }
}

extension NightscoutTreatment.EventType {
    /// The kind of a treatment event type.
    /// This enumeration describes an event type in the general sense,
    /// i.e. without any payload in the form of an associated value.
    public enum Kind: String {
        case bloodGlucoseCheck = "BG Check"
        case snackBolus = "Snack Bolus"
        case mealBolus = "Meal Bolus"
        case correctionBolus = "Correction Bolus"
        case comboBolus = "Combo Bolus"
        case temporaryBasal = "Temp Basal"
        case carbCorrection = "Carb Correction"
        case announcement = "Announcement"
        case note = "Note"
        case question = "Question"
        case exercise = "Exercise"
        case suspendPump = "Suspend Pump"
        case resumePump = "Resume Pump"
        case pumpSiteChange = "Site Change"
        case insulinChange = "Insulin Change"
        case sensorStart = "Sensor Start"
        case sensorChange = "Sensor Change"
        case profileSwitch = "Profile Switch"
        case diabeticAlertDogAlert = "D.A.D. Alert"
        case none = "<none>"
        case unknown
    }

    /// The kind of the treatment event type,
    /// i.e. its general description without any payload in the form of an associated value.
    public var kind: Kind {
        switch self {
        case .bloodGlucoseCheck(_):
            return .bloodGlucoseCheck
        case .bolus(let type):
            switch type {
            case .standard(let bolus):
                switch bolus.context {
                case .snack:
                    return .snackBolus
                case .meal:
                    return .mealBolus
                case .correction:
                    return .correctionBolus
                }
            case .combo(_):
                return .comboBolus
            }
        case .temporaryBasal(_):
            return .temporaryBasal
        case .carbCorrection(grams: _):
            return .carbCorrection
        case .announcement(_):
            return .announcement
        case .note:
            return .note
        case .question:
            return .question
        case .exercise(_):
            return .exercise
        case .suspendPump:
            return .suspendPump
        case .resumePump:
            return .resumePump
        case .pumpSiteChange:
            return .pumpSiteChange
        case .insulinChange:
            return .insulinChange
        case .sensorStart:
            return .sensorStart
        case .sensorChange:
            return .sensorChange
        case .profileSwitch(profileName: _):
            return .profileSwitch
        case .diabeticAlertDogAlert:
            return .diabeticAlertDogAlert
        case .none:
            return .none
        case .unknown(_):
            return .unknown
        }
    }
}

// MARK: - JSON

extension NightscoutTreatment: JSONParseable {
    enum Key {
        static let eventTypeString: JSONKey<String> = "eventType"
        static let dateString: JSONKey<String> = "created_at"
        static let durationInMinutes: JSONKey<Double> = "duration"
        static let insulinGiven: JSONKey<Double> = "insulin"
        static let carbsConsumed: JSONKey<Int> = "carbs"
        static let recorder: JSONKey<String> = "enteredBy"
        static let notes: JSONKey<String> = "notes"
    }

    static func parse(fromJSON treatmentJSON: JSONDictionary) -> NightscoutTreatment? {
        guard
            let id = NightscoutIdentifier.parse(fromJSON: treatmentJSON),
            let eventType = EventType.parse(fromJSON: treatmentJSON),
            let date = treatmentJSON[convertingDateFrom: Key.dateString]
        else {
            return nil
        }

        return .init(
            id: id,
            eventType: eventType,
            date: date,
            glucose: GlucoseMeasurement.parse(fromJSON: treatmentJSON),
            insulinGiven: treatmentJSON[Key.insulinGiven],
            carbsConsumed: treatmentJSON[Key.carbsConsumed],
            recorder: treatmentJSON[Key.recorder],
            notes: treatmentJSON[Key.notes]
        )
    }
}

extension NightscoutTreatment: JSONConvertible {
    var jsonRepresentation: JSONDictionary {
        var json: JSONDictionary = [:]

        json[NightscoutIdentifier.Key.id] = id.value
        json[Key.eventTypeString] = eventType.simpleRawValue
        json[Key.durationInMinutes] = duration?.minutes ?? 0
        json[convertingDateFrom: Key.dateString] = date
        json[Key.recorder] = recorder
        json[Key.notes] = notes

        switch eventType {
        case .bolus(.combo(let bolus)):
            json[ComboBolus.Key.totalInsulinString] = String(bolus.totalInsulin)
            json[ComboBolus.Key.percentageDeliveredUpFrontString] = String(bolus.percentageDeliveredUpFront)
            json[ComboBolus.Key.percentageDistributedOverTimeString] = String(bolus.percentageDistributedOverTime)
        case .temporaryBasal(let event):
            switch event {
            case .began(let temporaryBasal):
                switch temporaryBasal.type {
                case .percentage(let percentage):
                    json[TemporaryBasalType.Key.percentage] = percentage
                case .absolute(rate: let rate):
                    json[TemporaryBasalType.Key.absolute] = rate
                }
            case .ended:
                break
            }
        case .profileSwitch(let profileSwitchEvent):
            json[ProfileSwitchEvent.Key.profileName] = profileSwitchEvent.profileName
        case .announcement:
            json["isAnnouncement"] = 1
        default:
            break
        }

        if let glucose = glucose {
            json[GlucoseMeasurement.Key.glucoseValue] = glucose.glucoseValue.value
            json[convertingFrom: GlucoseMeasurement.Key.units] = glucose.glucoseValue.units
            json[convertingFrom: GlucoseMeasurement.Key.glucoseSource] = glucose.source
        }

        json[Key.carbsConsumed] = carbsConsumed
        json[Key.insulinGiven] = insulinGiven

        return json
    }
}

extension NightscoutTreatment.EventType: JSONParseable {
    static func parse(fromJSON treatmentJSON: JSONDictionary) -> NightscoutTreatment.EventType? {
        guard let eventTypeString = treatmentJSON[NightscoutTreatment.Key.eventTypeString] else {
            return nil
        }

        guard let kind = Kind(rawValue: eventTypeString) else {
            return .unknown(eventTypeString)
        }

        if let simpleEventType = NightscoutTreatment.EventType(simpleRawValue: eventTypeString) {
            return simpleEventType
        } else {
            // TODO: There's repetitive parsing in here.
            // e.g. A glucose measurement is parsed as an optional for the treatment,
            //      but then again in the case that the event type matches.
            //      The treatment date is also often parsed again.
            switch kind {
            case .bloodGlucoseCheck:
                return NightscoutTreatment.GlucoseMeasurement.parse(fromJSON: treatmentJSON).map(bloodGlucoseCheck)
            case .carbCorrection:
                return treatmentJSON[NightscoutTreatment.Key.carbsConsumed].map(carbCorrection)
            case .announcement:
                return treatmentJSON[NightscoutTreatment.Key.notes].map(announcement)
            case .note:
                return NoteEvent.parse(fromJSON: treatmentJSON).map(note)
            case .question:
                return treatmentJSON[NightscoutTreatment.Key.notes].map(question)
            case .exercise:
                return ExerciseEvent.parse(fromJSON: treatmentJSON).map(exercise)
            case .snackBolus, .mealBolus, .correctionBolus, .comboBolus:
                return BolusEvent.parse(fromJSON: treatmentJSON).map(bolus)
            case .temporaryBasal:
                return TemporaryBasalEvent.parse(fromJSON: treatmentJSON).map(temporaryBasal)
            case .profileSwitch:
                return ProfileSwitchEvent.parse(fromJSON: treatmentJSON).map(profileSwitch)
            default:
                fatalError("Kind \(kind) not matched to simple value nor expected case with associated value.")
            }
        }
    }
}

extension NightscoutTreatment.EventType: PartiallyRawRepresentable {
    static var simpleCases: [NightscoutTreatment.EventType] {
        return [
            .suspendPump, .resumePump, .pumpSiteChange, .insulinChange,
            .sensorStart, .sensorChange, .diabeticAlertDogAlert, .none
        ]
    }

    var simpleRawValue: String {
        return kind.rawValue
    }
}

extension NightscoutTreatment.GlucoseMeasurement: JSONParseable {
    fileprivate enum Key {
        static let glucoseValue: JSONKey<Double> = "glucose"
        static let units: JSONKey<BloodGlucoseUnit> = "units"
        static let glucoseSource: JSONKey<Source> = "glucoseType"
    }

    static func parse(fromJSON treatmentJSON: JSONDictionary) -> NightscoutTreatment.GlucoseMeasurement? {
        guard
            let value = treatmentJSON[Key.glucoseValue],
            let glucoseSource = treatmentJSON[convertingFrom: Key.glucoseSource]
        else {
            return nil
        }

        let units = treatmentJSON[convertingFrom: Key.units] ?? .milligramsPerDeciliter
        let glucoseValue = BloodGlucoseValue(value: value, units: units)
        return .init(glucoseValue: glucoseValue, source: glucoseSource)
    }
}

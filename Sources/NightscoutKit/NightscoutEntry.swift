//
//  NightscoutEntry.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 2/16/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Foundation


/// A Nightscout blood glucose entry.
/// This type stores data such as the glucose value (in mg/dL), its source (sensor or meter), the date at which the data was recorded, and the device from which the data was obtained.
public struct NightscoutEntry: UniquelyIdentifiable, BloodGlucoseUnitConvertible {
    /// Describes the source of a blood glucose entry.
    public enum Source {
        /// A continuous glucose monitor (CGM) reading. The associated value contains the blood glucose trend.
        case sensor(trend: BloodGlucoseTrend)

        /// A blood glucose meter reading.
        case meter
    }

    /// The entry's unique, internally assigned identifier.
    public let id: String

    /// The blood glucose value. Units are specified by the `units` property.
    public let glucoseValue: Double

    /// The blood glucose units in which the glucose value is measured.
    public let units: BloodGlucoseUnit

    /// The source of the blood glucose entry.
    public let source: Source

    /// The date at which the entry was recorded.
    public let date: Date

    /// The device from which the entry data was obtained.
    public let device: String?

    /// Creates a new blood glucose entry.
    /// - Parameter glucoseValue: The blood glucose value.
    /// - Parameter units: The blood glucose units in which the glucose vlaue is measured.
    /// - Parameter source: The source of the blood glucose entry.
    /// - Parameter date: The date at which the entry was recorded.
    /// - Parameter device: The device from which the entry data was obtained.
    /// - Returns: A new blood glucose entry.
    public init(glucoseValue: Double, units: BloodGlucoseUnit, source: Source, date: Date, device: String?) {
        self.init(id: IdentifierFactory.makeID(), glucoseValue: glucoseValue, units: units, source: source, date: date, device: device)
    }

    init(id: String, glucoseValue: Double, units: BloodGlucoseUnit, source: Source, date: Date, device: String?) {
        self.id = id
        self.glucoseValue = glucoseValue
        self.units = units
        self.source = source
        self.date = date
        self.device = device
    }

    /// Returns an entry converted to the specified blood glucose units.
    /// - Parameter units: The blood glucose units to which to convert.
    /// - Returns: An entry converted to the specified blood glucose units.
    public func converted(toUnits units: BloodGlucoseUnit) -> NightscoutEntry {
        let convertedGlucoseValue = BloodGlucoseUnit.convert(glucoseValue, from: self.units, to: units)
        return .init(id: id, glucoseValue: convertedGlucoseValue, units: units, source: source, date: date, device: device)
    }
}

// MARK: - JSON

extension NightscoutEntry: JSONParseable {
    typealias JSONParseType = JSONDictionary

    enum Key {
        static let id: JSONKey<String> = "_id"
        static let typeString: JSONKey<String> = "type"
        static let millisecondsSince1970: JSONKey<Int> = "date"
        static let dateString: JSONKey<String> = "dateString"
        static let device: JSONKey<String> = "device"
    }

    static func parse(fromJSON entryJSON: JSONDictionary) -> NightscoutEntry? {
        guard
            let id = entryJSON[Key.id],
            let millisecondsSince1970 = entryJSON[Key.millisecondsSince1970],
            let typeString = entryJSON[Key.typeString],
            let glucoseValue = entryJSON[typeString] as? Int, // Nightscout stores glucose values internally in mg/dL
            let source = Source.parse(fromJSON: entryJSON)
        else {
            return nil
        }

        return .init(
            id: id,
            glucoseValue: Double(glucoseValue),
            units: .milligramsPerDeciliter,
            source: source,
            date: Date(timeIntervalSince1970: .milliseconds(Double(millisecondsSince1970))),
            device: entryJSON[Key.device]
        )
    }
}

extension NightscoutEntry: JSONConvertible {
    var jsonRepresentation: JSONDictionary {
        var json: JSONDictionary = [:]
        json[Key.id] = id
        json[Key.millisecondsSince1970] = Int(date.timeIntervalSince1970.milliseconds)
        json[convertingDateFrom: Key.dateString] = date
        json[Key.typeString] = source.simpleRawValue
        json[source.simpleRawValue] = Int(BloodGlucoseUnit.convert(glucoseValue, from: units, to: .milligramsPerDeciliter))

        if case .sensor(trend: let trend) = source {
            json[convertingFrom: Source.Key.trend] = trend
        }

        if let device = device {
            json[Key.device] = device
        }

        return json
    }
}

extension NightscoutEntry.Source: JSONParseable {
    typealias JSONParseType = JSONDictionary
    
    fileprivate enum Key {
        static let trend: JSONKey<BloodGlucoseTrend> = "direction"
    }

    static func parse(fromJSON entryJSON: JSONDictionary) -> NightscoutEntry.Source? {
        guard let typeString = entryJSON[NightscoutEntry.Key.typeString] else {
            return nil
        }

        if let simpleGlucoseSource = NightscoutEntry.Source(simpleRawValue: typeString) {
            return simpleGlucoseSource
        } else {
            let trend = entryJSON[convertingFrom: Key.trend] ?? .unknown
            return .sensor(trend: trend)
        }
    }
}

extension NightscoutEntry.Source: PartiallyRawRepresentable {
    static var simpleCases: [NightscoutEntry.Source] {
        return [.meter]
    }

    var simpleRawValue: String {
        switch self {
        case .sensor(trend: _):
            return "sgv"
        case .meter:
            return "mbg"
        }
    }
}

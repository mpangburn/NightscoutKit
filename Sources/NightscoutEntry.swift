//
//  NightscoutEntry.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 2/16/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

/// A Nightscout blood glucose entry.
/// This type stores data such as the glucose value (in mg/dL), its source (sensor or meter), the date at which the data was recorded, and the device from which the data was obtained.
public struct NightscoutEntry: UniquelyIdentifiable {
    /// The source of a blood glucose entry.
    public enum Source {
        case sensor(trend: BloodGlucoseTrend)
        case meter
    }

    /// The entry's unique, internally assigned identifier.
    public let id: String

    /// The entry's glucose value in milligrams per deciliter (mg/dL).
    public let glucoseValue: Int

    /// The source of the blood glucose entry.
    public let source: Source

    /// The date at which the entry was recorded.
    public let date: Date

    /// The device from which the entry data was obtained.
    public let device: String?

    public init(glucoseValue: Int, source: Source, date: Date, device: String?) {
        self.init(id: IdentifierFactory.makeID(), glucoseValue: glucoseValue, source: source, date: date, device: device)
    }

    init(id: String, glucoseValue: Int, source: Source, date: Date, device: String?) {
        self.id = id
        self.glucoseValue = glucoseValue
        self.source = source
        self.date = date
        self.device = device
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
            let glucoseValue = entryJSON[typeString] as? Int,
            let source = Source.parse(fromJSON: entryJSON)
        else {
            return nil
        }

        return NightscoutEntry(
            id: id,
            glucoseValue: glucoseValue,
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
        json[source.simpleRawValue] = glucoseValue

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

// MARK: - CustomStringConvertible

extension NightscoutEntry: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        return description(includingID: false)
    }

    public var debugDescription: String {
        return description(includingID: true)
    }

    private func description(includingID: Bool) -> String {
        var description = "NightscoutEntry("
        if includingID {
            description += "id: \(id), "
        }
        description += "glucoseValue: \(glucoseValue) \(BloodGlucoseUnit.milligramsPerDeciliter), source: \(source), date: \(date)"
        if let device = device {
            description += ", device: \(device)"
        }
        description += ")"
        return description
    }
}

extension NightscoutEntry.Source: CustomStringConvertible {
    public var description: String {
        switch self {
        case .sensor(trend: let trend):
            return ".sensor(trend: \(trend))"
        case .meter:
            return ".meter"
        }
    }
}

//
//  NightscoutEntry.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 2/16/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

public struct NightscoutEntry: UniquelyIdentifiable {
    public enum Source {
        case sensor(trend: BloodGlucoseTrend)
        case meter
    }

    public let id: String
    public let glucoseValue: Int // Nightscout stores all BGs internally in mg/dL
    public let source: Source
    public let date: Date
    public let device: String?
}

// MARK: - JSON Parsing

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
    func json() -> JSONDictionary {
        var json: JSONDictionary = [:]
        json[Key.id] = id
        json[Key.millisecondsSince1970] = Int(date.timeIntervalSince1970.milliseconds)
        json[Key.dateString] = TimeFormatter.string(from: date)
        json[Key.typeString] = source.simpleRawValue
        json[source.simpleRawValue] = glucoseValue

        if case .sensor(trend: let trend) = source, trend != .unknown {
            json[Source.Key.direction] = trend.rawValue
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
        static let direction: JSONKey<String> = "direction"
    }

    static func parse(fromJSON entryJSON: JSONDictionary) -> NightscoutEntry.Source? {
        guard let typeString = entryJSON[NightscoutEntry.Key.typeString] else {
            return nil
        }

        if let simpleGlucoseSource = NightscoutEntry.Source(simpleRawValue: typeString) {
            return simpleGlucoseSource
        } else {
            let trend = entryJSON[Key.direction].flatMap(BloodGlucoseTrend.init(rawValue:)) ?? .unknown
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

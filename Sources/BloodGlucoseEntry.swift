//
//  BloodGlucoseEntry.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 2/16/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Foundation


public struct BloodGlucoseEntry: UniquelyIdentifiable {
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

extension BloodGlucoseEntry: JSONParseable {
    typealias JSONParseType = JSONDictionary

    enum Key {
        static let id = "_id"
        static let typeString = "type"
        static let millisecondsSince1970 = "date"
        static let dateString = "dateString"
        static let device = "device"
    }

    static func parse(fromJSON entryJSON: JSONDictionary) -> BloodGlucoseEntry? {
        guard
            let id = entryJSON[Key.id] as? String,
            let millisecondsSince1970 = entryJSON[Key.millisecondsSince1970] as? Double,
            let typeString = entryJSON[Key.typeString] as? String,
            let glucoseValue = entryJSON[typeString] as? Int,
            let source = Source.parse(fromJSON: entryJSON)
        else {
            return nil
        }

        return BloodGlucoseEntry(
            id: id,
            glucoseValue: glucoseValue,
            source: source,
            date: Date(timeIntervalSince1970: .milliseconds(millisecondsSince1970)),
            device: entryJSON[Key.device] as? String
        )
    }
}

extension BloodGlucoseEntry: JSONConvertible {
    func json() -> JSONDictionary {
        var raw: RawValue = [
            Key.id: id,
            Key.millisecondsSince1970: Int(date.timeIntervalSince1970.milliseconds),
            Key.dateString: TimeFormatter.string(from: date),
            Key.typeString: source.simpleRawValue,
            source.simpleRawValue: glucoseValue
        ]

        if case .sensor(trend: let trend) = source, trend != .unknown {
            raw[Source.Key.direction] = trend.rawValue
        }

        if let device = device {
            raw[Key.device] = device
        }

        return raw
    }
}

extension BloodGlucoseEntry.Source: JSONParseable {
    typealias JSONParseType = JSONDictionary
    
    fileprivate enum Key {
        static let direction = "direction"
    }

    static func parse(fromJSON entryJSON: JSONDictionary) -> BloodGlucoseEntry.Source? {
        guard let typeString = entryJSON[BloodGlucoseEntry.Key.typeString] as? String else {
            return nil
        }

        if let simpleGlucoseSource = BloodGlucoseEntry.Source(simpleRawValue: typeString) {
            return simpleGlucoseSource
        } else {
            let trend: BloodGlucoseTrend
            if let directionString = entryJSON[Key.direction] as? String, let bgTrend = BloodGlucoseTrend(rawValue: directionString) {
                trend = bgTrend
            } else {
                trend = .unknown
            }

            return .sensor(trend: trend)
        }
    }
}

extension BloodGlucoseEntry.Source: PartiallyRawRepresentable {
    static var simpleCases: [BloodGlucoseEntry.Source] {
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

extension BloodGlucoseEntry: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        return description(includingID: false)
    }

    public var debugDescription: String {
        return description(includingID: true)
    }

    private func description(includingID: Bool) -> String {
        var description = "BloodGlucoseEntry("
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

extension BloodGlucoseEntry.Source: CustomStringConvertible {
    public var description: String {
        switch self {
        case .sensor(trend: let trend):
            return ".sensor(trend: \(trend))"
        case .meter:
            return ".meter"
        }
    }
}

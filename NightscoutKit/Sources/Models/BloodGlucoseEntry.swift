//
//  BloodGlucoseEntry.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 2/16/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Foundation


struct BloodGlucoseEntry: UniquelyIdentifiable {
    enum Source {
        case sensor(trend: BloodGlucoseTrend)
        case meter
        case calibration
        case other
    }

    let id: String
    let glucoseValue: Int // TODO: can this be in mmol/L, or is it always uploaded in mg/dL?
    let source: Source
    let date: Date
    let device: String?
}

extension BloodGlucoseEntry: JSONParseable {
    fileprivate struct Key {
        static let id = "_id"
        static let typeString = "type"
        static let date = "date"
        static let dateString = "dateString"
        static let device = "device"
    }

    static func parse(from entryJSON: JSONDictionary) -> BloodGlucoseEntry? {
        guard
            let id = entryJSON[Key.id] as? String,
            let millisecondsSince1970 = entryJSON[Key.date] as? Double,
            let typeString = entryJSON[Key.typeString] as? String,
            let glucoseValue = entryJSON[typeString] as? Int,
            let source = Source.parse(from: entryJSON)
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
    var rawValue: JSONDictionary {
        var raw: RawValue = [
            Key.id: id,
            Key.date: Int(date.timeIntervalSince1970.milliseconds),
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
    fileprivate struct Key {
        static let direction = "direction"
    }

    static func parse(from entryJSON: JSONDictionary) -> BloodGlucoseEntry.Source? {
        guard let typeString = entryJSON[BloodGlucoseEntry.Key.typeString] as? String else {
            return nil
        }

        if let simpleGlucoseSource = BloodGlucoseEntry.Source(simpleRawValue: typeString) {
            return simpleGlucoseSource
        } else {
            guard typeString == "sgv" else {
                return nil
            }

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
        return [.meter, .calibration, .other]
    }

    var simpleRawValue: String {
        switch self {
        case .sensor(trend: _):
            return "sgv"
        case .meter:
            return "mbg"
        case .calibration:
            return "cal"
        case .other:
            return "etc"
        }
    }
}

//
//  NightscoutEntrySource.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 3/18/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Foundation


/// Describes the source of a blood glucose entry.
public enum NightscoutEntrySource {
    /// A continuous glucose monitor (CGM) reading. The associated value contains the blood glucose trend.
    case sensor(trend: BloodGlucoseTrend)

    /// A blood glucose meter reading.
    case meter
}

extension NightscoutEntrySource: JSONParseable {
    typealias JSONParseType = JSONDictionary

    enum Key {
        static let trend: JSONKey<BloodGlucoseTrend> = "direction"
    }

    static func parse(fromJSON entryJSON: JSONDictionary) -> NightscoutEntrySource? {
        guard let typeString = entryJSON[NightscoutEntry.Key.typeString] else {
            return nil
        }

        if let simpleGlucoseSource = NightscoutEntrySource(simpleRawValue: typeString) {
            return simpleGlucoseSource
        } else {
            let trend = entryJSON[convertingFrom: Key.trend] ?? .unknown
            return .sensor(trend: trend)
        }
    }
}

extension NightscoutEntrySource: PartiallyRawRepresentable {
    static var simpleCases: [NightscoutEntrySource] {
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

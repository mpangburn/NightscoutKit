//
//  NightscoutQueryItem.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 5/13/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Foundation


enum NightscoutQueryItem {
    case count(Int)
    case find(property: String, ComparativeOperator, value: String)

    enum ComparativeOperator: String {
        case lessThan = "lt"
        case lessThanOrEqualTo = "lte"
        case equalTo
        case greaterThanOrEqualTo = "gte"
        case greaterThan = "gt"
    }

    var urlQueryItem: URLQueryItem {
        switch self {
        case .count(let count):
            return URLQueryItem(name: "count", value: String(count))
        case .find(property: let property, let `operator`, value: let value):
            let operatorString = (`operator` == .equalTo) ? "" : "[$\(`operator`.rawValue)]"
            return URLQueryItem(name: "find[\(property)]\(operatorString)", value: value)
        }
    }

    static func entryDate(_ operator: ComparativeOperator, _ date: Date) -> NightscoutQueryItem {
        let millisecondsSince1970 = Int(date.timeIntervalSince1970.milliseconds)
        return .find(property: NightscoutEntry.Key.millisecondsSince1970.key, `operator`, value: String(millisecondsSince1970))
    }

    static func entryDates(from dateInterval: DateInterval) -> [NightscoutQueryItem] {
        return [.entryDate(.greaterThanOrEqualTo, dateInterval.start), .entryDate(.lessThanOrEqualTo, dateInterval.end)]
    }

    static func treatmentEventType(matching eventKind: NightscoutTreatment.EventType.Kind) -> NightscoutQueryItem {
        return .find(property: NightscoutTreatment.Key.eventTypeString.key, .equalTo, value: eventKind.rawValue)
    }

    static func treatmentDate(_ operator: ComparativeOperator, _ date: Date) -> NightscoutQueryItem {
        let dateString = "\(TimeFormatter.string(from: date)).000Z"
        return .find(property: NightscoutTreatment.Key.dateString.key, `operator`, value: dateString)
    }

    static func treatmentDates(from dateInterval: DateInterval) -> [NightscoutQueryItem] {
        return [.treatmentDate(.greaterThanOrEqualTo, dateInterval.start), .treatmentDate(.lessThanOrEqualTo, dateInterval.end)]
    }

    static func deviceStatusDate(_ operator: ComparativeOperator, _ date: Date) -> NightscoutQueryItem {
        let dateString = "\(TimeFormatter.string(from: date))Z"
        return .find(property: NightscoutDeviceStatus.Key.dateString.key, `operator`, value: dateString)
    }

    static func deviceStatusDates(from dateInterval: DateInterval) -> [NightscoutQueryItem] {
        return [.deviceStatusDate(.greaterThanOrEqualTo, dateInterval.start), .deviceStatusDate(.lessThanOrEqualTo, dateInterval.end)]
    }
}

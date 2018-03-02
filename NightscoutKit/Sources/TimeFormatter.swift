//
//  TimeFormatter.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 2/27/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Foundation


enum TimeFormatter {
    static func time(from string: String) -> TimeInterval? {
        return DateFormatter.gmtHourAndMinuteFormatter.date(from: string)?.timeIntervalSinceMidnight
    }

    static func date(from string: String) -> Date? {
        return ISO8601DateFormatter.gmtFormatter.date(from: string)
    }

    static func string(from date: Date) -> String {
        return ISO8601DateFormatter.gmtFormatter.string(from: date)
    }
}

fileprivate extension DateFormatter {
    static let gmtHourAndMinuteFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
}

fileprivate extension Date {
    var timeIntervalSinceMidnight: TimeInterval {
        let calendar = Calendar(identifier: .gregorian)
        let hours = calendar.component(.hour, from: self)
        let minutes = calendar.component(.minute, from: self)
        return .hours(Double(hours)) + .minutes(Double(minutes))
    }
}

fileprivate extension ISO8601DateFormatter {
    static let gmtFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = .withInternetDateTime
        formatter.formatOptions.subtract(.withTimeZone)
        return formatter
    }()
}

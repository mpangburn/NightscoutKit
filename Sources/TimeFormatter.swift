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
        let date = DateFormatter.hourAndMinuteFormatter.date(from: string)
        return date?.timeIntervalSinceMidnight
    }

    static func string(from time: TimeInterval) -> String {
        let date = Date().midnight + time
        return DateFormatter.prettyTimeFormatter.string(from: date)
    }

    static func date(from string: String) -> Date? {
        return ISO8601DateFormatter.gmtFormatter.date(from: string)
    }

    static func string(from date: Date) -> String {
        return ISO8601DateFormatter.gmtFormatter.string(from: date)
    }
}

fileprivate extension DateFormatter {
    static let hourAndMinuteFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = TimeZone(secondsFromGMT: Int(TimeInterval(hours: -8))) // for some reason we have to use PST here
        return formatter
    }()

    static let prettyTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
}

fileprivate extension Date {
    var midnight: Date {
        let calendar = Calendar(identifier: .iso8601)
        return calendar.startOfDay(for: self)
    }

    var timeIntervalSinceMidnight: TimeInterval {
        return timeIntervalSince(midnight)
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

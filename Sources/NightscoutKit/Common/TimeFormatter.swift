//
//  TimeFormatter.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 2/27/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Foundation
import Oxygen


internal enum TimeFormatter {
    static func time(from string: String) -> TimeInterval? {
        let date = DateFormatter.hourAndMinuteFormatter.date(from: string)
        return date?.timeIntervalSinceMidnight
    }

    static func string(from time: TimeInterval) -> String {
        let date = Date().midnight + time
        return DateFormatter.hourAndMinuteFormatter.string(from: date)
    }

    static func prettyString(from time: TimeInterval) -> String {
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
    static let hourAndMinuteFormatter = with(DateFormatter()) {
        $0.dateFormat = "HH:mm"
    }

    static let prettyTimeFormatter = with(DateFormatter()) {
        $0.dateStyle = .none
        $0.timeStyle = .short
    }
}

// TODO: ISO8601 is the bottleneck for NightscoutKit to support older firmware versions.
// This requires iOS 10.0+, macOS 10.12+, tvOS 10.0+, watchOS 3.0+.

fileprivate extension ISO8601DateFormatter {
    static let gmtFormatter = with(ISO8601DateFormatter()) {
        $0.formatOptions = .withInternetDateTime
        $0.formatOptions.subtract(.withTimeZone)
    }
}

//
//  TimelinePeriod.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 5/9/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Foundation


/// A type that can be described by its start and end dates.
public protocol TimelinePeriod {
    /// The start date of the period.
    var startDate: Date { get }

    /// The duration of the period.
    var duration: TimeInterval { get }

    /// The end date of the period.
    var endDate: Date { get }
}

// MARK: - Default Implementations

extension TimelinePeriod {
    public var endDate: Date {
        return startDate + duration
    }
}

// MARK: - Extension Methods

extension TimelinePeriod {
    /// Returns a boolean value representing whether the event is in progress at the given date.
    /// - Parameter date: The date to test. Defaults to the current date.
    /// - Returns: A boolean value representing whether the given date falls within the event's start and end dates.
    public func isInProgress(at date: Date = Date()) -> Bool {
        return startDate...endDate ~= date
    }
}

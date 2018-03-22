//
//  DeltaRecordingNighscoutEntry.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 3/18/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Foundation


/// A Nightscout blood glucose entry that records data in relation to the previous entry,
/// such as the change in glucose value, time elapsed, and glucose rate of change.
public struct DeltaRecordingNightscoutEntry: NightscoutEntryProtocol {
    /// The entry's unique, internally assigned identifier.
    public let id: String

    /// The blood glucose value and the units in which it is measured.
    public let glucoseValue: BloodGlucoseValue

    /// The source of the blood glucose entry.
    public let source: NightscoutEntrySource

    /// The date at which the entry was recorded.
    public let date: Date

    /// The device from which the entry data was obtained.
    public let device: String?

    /// The blood glucose entry recorded most recently prior to this entry.
    public let previousEntry: NightscoutEntry

    /// The change in glucose value since the previous entry.
    public var glucoseDeltaFromPreviousEntry: Double {
        return glucoseValue.value - previousEntry.glucoseValue.value
    }

    /// The time interval elapsed since the previous entry.
    public var timeIntervalSincePreviousEntry: TimeInterval {
        return date.timeIntervalSince(previousEntry.date)
    }

    /// The rate of change of the glucose value since the previous entry.
    /// Units are in `units` blood glucose units per minute (<blood glucose unit>/min).
    public var glucoseRateOfChange: Double {
        return glucoseDeltaFromPreviousEntry / timeIntervalSincePreviousEntry.minutes
    }

    /// Creates a new blood glucose entry recording data in relation to the previous entry.
    /// - Parameter entry: The entry to recreate.
    /// - Parameter previousEntry: The entry occurring prior to this entry.
    /// - Returns: A new blood glucose entry recording data in relation to the previous entry.
    public init(entry: NightscoutEntry, previousEntry: NightscoutEntry) {
        assert(entry.glucoseValue.units == previousEntry.glucoseValue.units)
        self.init(
            id: entry.id,
            glucoseValue: entry.glucoseValue,
            source: entry.source,
            date: entry.date,
            device: entry.device,
            previousEntry: previousEntry
        )
    }

    init(id: String, glucoseValue: BloodGlucoseValue, source: NightscoutEntrySource, date: Date, device: String?, previousEntry: NightscoutEntry) {
        self.id = id
        self.glucoseValue = glucoseValue
        self.source = source
        self.date = date
        self.device = device
        self.previousEntry = previousEntry
    }

    /// Returns an entry converted to the specified blood glucose units.
    /// - Parameter units: The blood glucose units to which to convert.
    /// - Returns: An entry converted to the specified blood glucose units.
    public func converted(to units: BloodGlucoseUnit) -> DeltaRecordingNightscoutEntry {
        return .init(
            id: id,
            glucoseValue: glucoseValue.converted(to: units),
            source: source,
            date: date,
            device: device,
            previousEntry: previousEntry.converted(to: units)
        )
    }
}

extension Array where Element == NightscoutEntry {
    /// Returns an array of entries, each of which records data in relation to the entry before it.
    /// Note that if the array contains only a single entry, this function will return an empty array.
    /// If the blood glucose units of the entries in the array do not match up,
    /// the data provided by this operation will be unhelpful.
    /// - Precondition: The array must be in descending order by date (i.e. most recent entries first).
    /// - Returns: An array of entries, each of which records data in relation to the entry before it.
    public func recordingDeltas() -> [DeltaRecordingNightscoutEntry] {
        return adjacentPairs().map(DeltaRecordingNightscoutEntry.init(entry:previousEntry:))
    }
}

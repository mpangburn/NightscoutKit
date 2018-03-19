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
    /// Describes the source of a blood glucose entry.
    public typealias Source = NightscoutEntrySource

    /// The entry's unique, internally assigned identifier.
    public let id: String

    /// The blood glucose value. Units are specified by the `units` property.
    public let glucoseValue: Double

    /// The blood glucose units in which the glucose value is measured.
    public let units: BloodGlucoseUnit

    /// The source of the blood glucose entry.
    public let source: Source

    /// The date at which the entry was recorded.
    public let date: Date

    /// The device from which the entry data was obtained.
    public let device: String?

    /// The blood glucose entry recorded most recently prior to this entry.
    public let previousEntry: NightscoutEntry

    /// The change in glucose value since the previous entry.
    public var glucoseDeltaFromPreviousEntry: Double {
        return glucoseValue - previousEntry.glucoseValue
    }

    /// The time interval elapsed since the previous entry.
    public var timeIntervalSincePreviousEntry: TimeInterval {
        return date.timeIntervalSince(previousEntry.date)
    }

    /// The rate of change of the glucose value since the previous entry.
    /// Units are in `units` blood glucose units per minute (<blood glucose unit>/min).
    public var glucoseRateOfChange: Double {
        return glucoseDeltaFromPreviousEntry / .minutes(timeIntervalSincePreviousEntry)
    }

    /// Creates a new blood glucose entry recording data in relation to the previous entry.
    /// - Parameter entry: The entry to recreate.
    /// - Parameter previousEntry: The entry occurring prior to this entry.
    /// - Returns: A new blood glucose entry recording data in relation to the previous entry.
    public init(entry: NightscoutEntry, previousEntry: NightscoutEntry) {
        self.init(
            id: entry.id,
            glucoseValue: entry.glucoseValue,
            units: entry.units,
            source: entry.source,
            date: entry.date,
            device: entry.device,
            previousEntry: previousEntry
        )
    }

    init(id: String, glucoseValue: Double, units: BloodGlucoseUnit, source: NightscoutEntry.Source, date: Date, device: String?, previousEntry: NightscoutEntry) {
        self.id = id
        self.glucoseValue = glucoseValue
        self.units = units
        self.source = source
        self.date = date
        self.device = device
        self.previousEntry = previousEntry
    }

    /// Returns an entry converted to the specified blood glucose units.
    /// - Parameter units: The blood glucose units to which to convert.
    /// - Returns: An entry converted to the specified blood glucose units.
    public func converted(toUnits units: BloodGlucoseUnit) -> DeltaRecordingNightscoutEntry {
        let convertedGlucoseValue = BloodGlucoseUnit.convert(glucoseValue, from: self.units, to: units)
        return .init(
            id: id,
            glucoseValue: convertedGlucoseValue,
            units: units,
            source: source,
            date: date,
            device: device,
            previousEntry: previousEntry.converted(toUnits: units)
        )
    }
}

extension Array where Element == NightscoutEntry {
    /// Returns an array of entries, each of which records data in relation to the entry before it.
    /// Note that if the array contains only a single entry, this function will return an empty array.
    /// - Precondition: The array must be in descending order by date (i.e. most recent entries first).
    /// - Returns: An array of entries, each of which records data in relation to the entry before it.
    public func recordingDeltas() -> [DeltaRecordingNightscoutEntry] {
        return adjacentPairs().map(DeltaRecordingNightscoutEntry.init(entry:previousEntry:))
    }
}

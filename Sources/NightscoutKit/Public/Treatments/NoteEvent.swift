//
//  NoteEvent.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 5/9/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Foundation


/// Describes a treatment event containing a note.
public struct NoteEvent: TimelinePeriod, Hashable {
    /// The date at which the note was written.
    public let startDate: Date

    /// The period of time for which the note is applicable.
    public let duration: TimeInterval

    /// The message contained by the note.
    public let message: String

    /// Creates a new note.
    /// - Parameter startDate: The date at which the note was written.
    /// - Parameter duration: The period of time for which the note is applicable.
    /// - Parameter message: The message contained by the note.
    /// - Returns: A new note.
    public init(startDate: Date, duration: TimeInterval, message: String) {
        self.startDate = startDate
        self.duration = duration
        self.message = message
    }

    /// Creates a new note.
    /// - Parameter date: The date at which the note was written.
    /// - Parameter message: The message contained by the note.
    /// - Returns: A new note.
    public init(date: Date, message: String) {
        self.init(startDate: date, duration: 0, message: message)
    }
}

// MARK: - JSON

extension NoteEvent: JSONParseable {
    private typealias Key = NightscoutTreatment.Key

    static func parse(fromJSON treatmentJSON: JSONDictionary) -> NoteEvent? {
        guard
            let startDate = treatmentJSON[convertingDateFrom: Key.dateString],
            let duration = treatmentJSON[Key.durationInMinutes].map(TimeInterval.minutes),
            let message = treatmentJSON[Key.notes]
        else {
            return nil
        }

        return .init(startDate: startDate, duration: duration, message: message)
    }
}

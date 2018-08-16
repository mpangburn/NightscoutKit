//
//  ExerciseEvent.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 5/9/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Foundation


/// Describes an exercise event.
public struct ExerciseEvent: TimelinePeriod, Hashable, Codable {
    /// The date at which the exercise began.
    public let startDate: Date

    /// The duration of the exercise.
    public let duration: TimeInterval

    /// Creates a new exercise event.
    /// - Parameter startDate: The date at which the exercise began.
    /// - Parameter duration: The duration of the exercise.
    /// - Returns: A new exercise event.
    public init(startDate: Date, duration: TimeInterval) {
        self.startDate = startDate
        self.duration = duration
    }
}

// MARK: - JSON

extension ExerciseEvent: JSONParseable {
    private typealias Key = NightscoutTreatment.Key

    static func parse(fromJSON treatmentJSON: JSONDictionary) -> ExerciseEvent? {
        guard
            let startDate = treatmentJSON[convertingDateFrom: Key.dateString],
            let duration = treatmentJSON[Key.durationInMinutes].map(TimeInterval.minutes)
        else {
            return nil
        }

        return .init(startDate: startDate, duration: duration)
    }
}

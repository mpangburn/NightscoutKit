//
//  ProfileSwitchEvent.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 5/10/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Foundation


/// Describes a profile switch event.
public struct ProfileSwitchEvent: TimelinePeriod, Hashable {
    /// The date of the profile switch event.
    public let startDate: Date

    /// The duration of the profile switch.
    /// If the switch does not define a finite interval, this value will be `TimeInterval.infinity`.
    public let duration: TimeInterval

    /// The name of the profile made active in the profile switch event.
    public let profileName: String

    /// Creates a new profile switch event with finite duration.
    /// - Parameter startDate: The date of the profile switch event.
    /// - Parameter duration: The duration of the profile switch.
    /// - Parameter profileName: The name of the profile made active in the profile switch event.
    /// - Returns: A new profile switch event.
    public init(startDate: Date, duration: TimeInterval, profileName: String) {
        self.startDate = startDate
        self.duration = duration
        self.profileName = profileName
    }

    /// Creates a new profile switch event with no finite duration.
    /// - Parameter date: The date of the profile switch event.
    /// - Parameter profileName: The name of the profile made active in the profile switch event.
    /// - Returns: A new profile switch event with no finite duration.
    public init(date: Date, profileName: String) {
        self.init(startDate: date, duration: .infinity, profileName: profileName)
    }
}

// MARK: - JSON

extension ProfileSwitchEvent: JSONParseable {
    enum Key {
        static let profileName: JSONKey<String> = "profile"
    }

    static func parse(fromJSON treatmentJSON: JSONDictionary) -> ProfileSwitchEvent? {
        guard
            let startDate = treatmentJSON[convertingDateFrom: NightscoutTreatment.Key.dateString],
            let profileName = treatmentJSON[Key.profileName]
        else {
            return nil
        }

        if let duration = treatmentJSON[NightscoutTreatment.Key.durationInMinutes].map(TimeInterval.minutes) {
            return .init(startDate: startDate, duration: duration, profileName: profileName)
        } else {
            return .init(date: startDate, profileName: profileName)
        }
    }
}

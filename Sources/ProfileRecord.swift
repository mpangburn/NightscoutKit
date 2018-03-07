//
//  ProfileRecord.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 2/23/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Foundation


public struct ProfileRecord: UniquelyIdentifiable {
    public let id: String
    public let defaultProfileName: String
    public let recordDate: Date
    public let units: BloodGlucoseUnit
    public let profiles: [String: Profile]
}

// MARK: - JSON Parsing

extension ProfileRecord: JSONParseable {
    private enum Key {
        static let id = "_id"
        static let defaultProfileName = "defaultProfile"
        static let recordDateString = "startDate"
        static let unitString = "units"
        static let profileDictionaries = "store"
    }

    static func parse(from profileJSON: JSONDictionary) -> ProfileRecord? {
        guard
            let id = profileJSON[Key.id] as? String,
            let defaultProfileName = profileJSON[Key.defaultProfileName] as? String,
            let recordDateString = profileJSON[Key.recordDateString] as? String,
            let recordDate = TimeFormatter.date(from: recordDateString),
            let unitString = profileJSON[Key.unitString] as? String,
            let units = BloodGlucoseUnit(rawValue: unitString),
            let profileDictionaries = profileJSON[Key.profileDictionaries] as? [String: JSONDictionary]
        else {
            return nil
        }

        return ProfileRecord(
            id: id,
            defaultProfileName: defaultProfileName,
            recordDate: recordDate,
            units: units,
            profiles: profileDictionaries.compactMapValues(Profile.parse)
        )
    }
}

extension ProfileRecord: JSONConvertible {
    public var rawValue: [String: Any] {
        return [
            Key.id: id,
            Key.defaultProfileName: defaultProfileName,
            Key.recordDateString: TimeFormatter.string(from: recordDate),
            Key.unitString: units.rawValue,
            Key.profileDictionaries: profiles.mapValues { $0.rawValue }
        ]
    }
}

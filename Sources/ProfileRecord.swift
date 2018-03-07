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
    public let date: Date
    public let units: BloodGlucoseUnit
    public let profiles: [String: Profile]
}

// MARK: - JSON Parsing

extension ProfileRecord: JSONParseable {
    typealias JSONParseType = JSONDictionary

    private enum Key {
        static let id = "_id"
        static let defaultProfileName = "defaultProfile"
        static let dateString = "startDate"
        static let unitString = "units"
        static let profileDictionaries = "store"
    }

    static func parse(fromJSON profileJSON: JSONDictionary) -> ProfileRecord? {
        guard
            let id = profileJSON[Key.id] as? String,
            let defaultProfileName = profileJSON[Key.defaultProfileName] as? String,
            let recordDateString = profileJSON[Key.dateString] as? String,
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
            date: recordDate,
            units: units,
            profiles: profileDictionaries.compactMapValues(Profile.parse)
        )
    }
}

extension ProfileRecord: JSONConvertible {
    func json() -> JSONDictionary {
        return [
            Key.id: id,
            Key.defaultProfileName: defaultProfileName,
            Key.dateString: TimeFormatter.string(from: date),
            Key.unitString: units.rawValue,
            Key.profileDictionaries: profiles.mapValues { $0.rawValue }
        ]
    }
}

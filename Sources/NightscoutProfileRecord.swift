//
//  NightscoutProfileRecord.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 2/23/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

public struct NightscoutProfileRecord: UniquelyIdentifiable {
    public let id: String
    public let defaultProfileName: String
    public let date: Date
    public let units: BloodGlucoseUnit
    public let profiles: [String: NightscoutProfile]

    public init(defaultProfileName: String, date: Date, units: BloodGlucoseUnit, profiles: [String: NightscoutProfile]) {
        self.init(id: IdentifierFactory.makeID(), defaultProfileName: defaultProfileName, date: date, units: units, profiles: profiles)
    }

    init(id: String, defaultProfileName: String, date: Date, units: BloodGlucoseUnit, profiles: [String: NightscoutProfile]) {
        self.id = id
        self.defaultProfileName = defaultProfileName
        self.date = date
        self.units = units
        self.profiles = profiles
    }
}

// MARK: - JSON

extension NightscoutProfileRecord: JSONParseable {
    typealias JSONParseType = JSONDictionary

    private enum Key {
        static let id: JSONKey<String> = "_id"
        static let defaultProfileName: JSONKey<String> = "defaultProfile"
        static let dateString: JSONKey<String> = "startDate"
        static let units: JSONKey<BloodGlucoseUnit> = "units"
        static let profileDictionaries: JSONKey<[String: JSONDictionary]> = "store"
    }

    static func parse(fromJSON profileJSON: JSONDictionary) -> NightscoutProfileRecord? {
        guard
            let id = profileJSON[Key.id],
            let defaultProfileName = profileJSON[Key.defaultProfileName],
            let recordDate = profileJSON[convertingDateFrom: Key.dateString],
            let units = profileJSON[convertingFrom: Key.units],
            let profileDictionaries = profileJSON[Key.profileDictionaries]
        else {
            return nil
        }

        return NightscoutProfileRecord(
            id: id,
            defaultProfileName: defaultProfileName,
            date: recordDate,
            units: units,
            profiles: profileDictionaries.compactMapValues(NightscoutProfile.parse)
        )
    }
}

extension NightscoutProfileRecord: JSONConvertible {
    var jsonRepresentation: JSONDictionary {
        var json: JSONDictionary = [:]
        json[Key.id] = id
        json[Key.defaultProfileName] = defaultProfileName
        json[convertingDateFrom: Key.dateString] = date
        json[convertingFrom: Key.units] = units
        json[Key.profileDictionaries] = profiles.mapValues { $0.jsonRepresentation }
        return json
    }
}

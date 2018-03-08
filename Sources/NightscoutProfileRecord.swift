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
}

// MARK: - JSON

extension NightscoutProfileRecord: JSONParseable {
    typealias JSONParseType = JSONDictionary

    private enum Key {
        static let id: JSONKey<String> = "_id"
        static let defaultProfileName: JSONKey<String> = "defaultProfile"
        static let dateString: JSONKey<String> = "startDate"
        static let unitString: JSONKey<String> = "units"
        static let profileDictionaries: JSONKey<[String: JSONDictionary]> = "store"
    }

    static func parse(fromJSON profileJSON: JSONDictionary) -> NightscoutProfileRecord? {
        guard
            let id = profileJSON[Key.id],
            let defaultProfileName = profileJSON[Key.defaultProfileName],
            let recordDate = profileJSON[Key.dateString].flatMap(TimeFormatter.date(from:)),
            let units = profileJSON[Key.unitString].flatMap(BloodGlucoseUnit.init(rawValue:)),
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
    func json() -> JSONDictionary {
        var json: JSONDictionary = [:]
        json[Key.id] = id
        json[Key.defaultProfileName] = defaultProfileName
        json[Key.dateString] = TimeFormatter.string(from: date)
        json[Key.unitString] = units.rawValue
        json[Key.profileDictionaries] = profiles.mapValues { $0.json() }
        return json
    }
}

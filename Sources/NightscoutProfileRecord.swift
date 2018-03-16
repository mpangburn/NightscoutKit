//
//  NightscoutProfileRecord.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 2/23/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

/// A Nightscout profile record.
/// This type stores data such as the user's profiles and the blood glucose units used in specifying details of these profiles.
public struct NightscoutProfileRecord: UniquelyIdentifiable {
    /// The profile record's unique, internally assigned identifier.
    public let id: String

    /// The name of the default profile.
    /// If the `profiles` dictionary does not contain this key, the profile record is malformed.
    public let defaultProfileName: String

    /// The date at which this profile record was last validated by the user.
    public let date: Date

    /// The blood glucose units used in creating the profiles' blood glucose target and insulin sensitivity schedules.
    public let bloodGlucoseUnits: BloodGlucoseUnit

    /// A dictionary containing the profiles, keyed by the profile names.
    public let profiles: [String: NightscoutProfile]

    /// The record's default profile. If the `profiles` dictionary does not contain the `defaultProfileName` key,
    /// this property will return the first entry in the `profiles` dictionary.
    /// An empty `profiles` dictionary can result only from a programmer error, so accessing this property
    /// in such a case will result in a crash.
    public var defaultProfile: NightscoutProfile {
        let defaultProfile = profiles[defaultProfileName]
        assert(defaultProfile != nil)
        return defaultProfile ?? profiles.first!.value
    }

    public init(defaultProfileName: String, date: Date, bloodGlucoseUnits: BloodGlucoseUnit, profiles: [String: NightscoutProfile]) {
        self.init(id: IdentifierFactory.makeID(), defaultProfileName: defaultProfileName, date: date, bloodGlucoseUnits: bloodGlucoseUnits, profiles: profiles)
    }

    init(id: String, defaultProfileName: String, date: Date, bloodGlucoseUnits: BloodGlucoseUnit, profiles: [String: NightscoutProfile]) {
        self.id = id
        self.defaultProfileName = defaultProfileName
        self.date = date
        self.bloodGlucoseUnits = bloodGlucoseUnits
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

        let profiles = profileDictionaries.compactMapValues(NightscoutProfile.parse)
        guard !profiles.isEmpty else {
            return nil
        }

        return .init(
            id: id,
            defaultProfileName: defaultProfileName,
            date: recordDate,
            bloodGlucoseUnits: units,
            profiles: profiles
        )
    }
}

extension NightscoutProfileRecord: JSONConvertible {
    var jsonRepresentation: JSONDictionary {
        var json: JSONDictionary = [:]
        json[Key.id] = id
        json[Key.defaultProfileName] = defaultProfileName
        json[convertingDateFrom: Key.dateString] = date
        json[convertingFrom: Key.units] = bloodGlucoseUnits
        json[Key.profileDictionaries] = profiles.mapValues { $0.jsonRepresentation }
        return json
    }
}

//
//  NightscoutSnapshot.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 3/1/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Foundation


public struct NightscoutSnapshot {
    public let date: Date
    public let settings: NightscoutSettings
    public let bloodGlucoseEntries: [BloodGlucoseEntry]
    public let treatments: [Treatment]
    public let profileRecords: [ProfileRecord]
}

extension NightscoutSnapshot: CustomStringConvertible {
    public var description: String {
        return """
        ===== NIGHTSCOUT SNAPSHOT =====
        \(date)

        ===== SETTINGS =====
        \(settings)

        ===== BLOOD GLUCOSE ENTRIES =====
        \(bloodGlucoseEntries.map(String.init(describing:)).joined(separator: "\n"))

        ===== TREATMENTS =====
        \(treatments.map(String.init(describing:)).joined(separator: "\n"))

        ===== PROFILE STORE SNAPSHOTS =====
        \(profileRecords.map(String.init(describing:)).joined(separator: "\n"))
        """
    }
}

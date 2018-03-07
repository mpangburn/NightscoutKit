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
    public let entries: [NightscoutEntry]
    public let treatments: [NightscoutTreatment]
    public let profileRecords: [NightscoutProfileRecord]
}

extension NightscoutSnapshot: CustomStringConvertible {
    public var description: String {
        return """
        ===== NIGHTSCOUT SNAPSHOT =====
        \(date)

        ===== SETTINGS =====
        \(settings)

        ===== BLOOD GLUCOSE ENTRIES =====
        \(entries.map(String.init(describing:)).joined(separator: "\n"))

        ===== TREATMENTS =====
        \(treatments.map(String.init(describing:)).joined(separator: "\n"))

        ===== PROFILE STORE SNAPSHOTS =====
        \(profileRecords.map(String.init(describing:)).joined(separator: "\n"))
        """
    }
}

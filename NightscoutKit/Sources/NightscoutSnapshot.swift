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
    public internal(set) var settings: NightscoutSettings
    public internal(set) var recentBloodGlucoseEntries: [BloodGlucoseEntry]
    public internal(set) var recentTreatments: [Treatment]
    public internal(set) var profileStoreSnapshots: [ProfileStoreSnapshot]
}

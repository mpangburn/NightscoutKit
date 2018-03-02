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
    public let recentBloodGlucoseEntries: [BloodGlucoseEntry]
    public let recentTreatments: [Treatment]
    public let profileStoreSnapshots: [ProfileStoreSnapshot]
}

//
//  NightscoutSnapshot.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 3/1/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Foundation


public struct NightscoutSnapshot {
    let date: Date
    let settings: NightscoutSettings
    let recentEntries: [BloodGlucoseEntry]
    let recentTreatments: [Treatment]
    let profileStoreSnapshots: [ProfileStoreSnapshot]
}

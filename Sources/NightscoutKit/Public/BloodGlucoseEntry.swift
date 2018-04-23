//
//  BloodGlucoseEntry.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 4/22/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

public protocol BloodGlucoseEntry: TimelineValue, BloodGlucoseUnitConvertible {
    var glucoseValue: BloodGlucoseValue { get }
}

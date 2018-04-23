//
//  BloodGlucoseEntry.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 4/22/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

/// A type representing a blood glucose entry.
public protocol BloodGlucoseEntry: TimelineValue, BloodGlucoseUnitConvertible {
    /// The recorded blood glucose value.
    var glucoseValue: BloodGlucoseValue { get }
}

//
//  NightscoutEntrySource.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 3/18/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Foundation


/// Describes the source of a blood glucose entry.
public enum NightscoutEntrySource {
    /// A continuous glucose monitor (CGM) reading. The associated value contains the blood glucose trend.
    case sensor(trend: BloodGlucoseTrend)

    /// A blood glucose meter reading.
    case meter
}

//
//  BatteryStatusProtocol.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 3/14/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

/// A type describing the status of a battery.
public protocol BatteryStatusProtocol {
    /// The status of the battery.
    var status: BatteryIndicator? { get }

    /// The voltage of the battery.
    var voltage: Double? { get }
}

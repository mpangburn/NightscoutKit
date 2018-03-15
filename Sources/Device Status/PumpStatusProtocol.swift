//
//  PumpStatusProtocol.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 3/14/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

/// A type describing the status of an insulin pump.
public protocol PumpStatusProtocol {
    /// Describes the battery status of the pump.
    associatedtype BatteryStatus: BatteryStatusProtocol

    /// The date of the pump clock.
    var clockDate: Date { get }

    /// The reservoir insulin remaining in units (U).
    var reservoirInsulinRemaining: Double? { get }

    /// The status of the pump battery.
    var batteryStatus: BatteryStatus? { get }

    /// A boolean value representing whether the pump is currently bolusing.
    var isBolusing: Bool? { get }

    /// A boolean value representing whether the pump is currently suspended.
    var isSuspended: Bool? { get }
}

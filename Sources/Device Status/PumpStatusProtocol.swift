//
//  PumpStatusProtocol.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 3/14/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

public protocol PumpStatusProtocol {
    associatedtype BatteryStatus: BatteryStatusProtocol

    var clockDate: Date { get }
    var reservoirInsulinRemaining: Double? { get }
    var batteryStatus: BatteryStatus? { get }
    var isBolusing: Bool? { get }
    var isSuspended: Bool? { get }
}

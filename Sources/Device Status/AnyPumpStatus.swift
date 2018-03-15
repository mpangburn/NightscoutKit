//
//  AnyPumpStatus.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 3/14/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

public struct AnyPumpStatus: PumpStatusProtocol {
    public struct BatteryStatus: BatteryStatusProtocol {
        public let status: BatteryIndicator?
        public let voltage: Double?
    }

    public let clockDate: Date
    public let reservoirInsulinRemaining: Double?
    public let batteryStatus: BatteryStatus?
    public var isBolusing: Bool?
    public var isSuspended: Bool?

    init<T: PumpStatusProtocol>(_ pumpStatus: T) {
        self.clockDate = pumpStatus.clockDate
        self.reservoirInsulinRemaining = pumpStatus.reservoirInsulinRemaining
        self.batteryStatus = BatteryStatus(status: pumpStatus.batteryStatus?.status, voltage: pumpStatus.batteryStatus?.voltage)
        self.isBolusing = pumpStatus.isBolusing
        self.isSuspended = pumpStatus.isSuspended
    }
}

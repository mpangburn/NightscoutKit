//
//  BatteryStatusProtocol.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 3/14/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

public protocol BatteryStatusProtocol {
    var status: BatteryIndicator? { get }
    var voltage: Double? { get }
}

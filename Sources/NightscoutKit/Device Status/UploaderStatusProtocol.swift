//
//  UploaderStatusProtocol.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 3/14/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

/// A type describing the status of a device uploading data to Nightscout.
public protocol UploaderStatusProtocol {
    /// The percentage of battery remaining of the uploading device.
    var batteryPercentage: Int? { get }
}

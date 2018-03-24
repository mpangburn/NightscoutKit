//
//  TemporaryBasalProtocol.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 3/14/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Foundation


/// A type describing a temporary basal.
public protocol TemporaryBasalProtocol {
    /// The start date of the temporary basal.
    var startDate: Date { get }

    /// The basal rate in units per hour (U/hr).
    var rate: Double { get }

    /// The duration of the temporary basal.
    var duration: TimeInterval { get }
}

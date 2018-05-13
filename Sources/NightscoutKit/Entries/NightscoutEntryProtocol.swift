//
//  NightscoutEntryProtocol.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 3/18/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

/// A type fulfilling the role of a Nightscout blood glucose entry.
public protocol NightscoutEntryProtocol: NightscoutIdentifiable, BloodGlucoseEntry {
    /// The source of the blood glucose entry.
    var source: NightscoutEntrySource { get }

    /// The device from which the entry data was obtained.
    var device: String? { get }
}

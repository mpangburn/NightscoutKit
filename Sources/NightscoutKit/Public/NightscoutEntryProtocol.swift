//
//  NightscoutEntryProtocol.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 3/18/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Foundation


/// A type fulfilling the role of a Nightscout blood glucose entry.
public protocol NightscoutEntryProtocol: UniquelyIdentifiable, BloodGlucoseEntry {
    /// The entry's unique, internally assigned identifier.
    var id: String { get }

    /// The blood glucose value and the units in which it is measured.
    var glucoseValue: BloodGlucoseValue { get }

    /// The source of the blood glucose entry.
    var source: NightscoutEntrySource { get }

    /// The date at which the entry was recorded.
    var date: Date { get }

    /// The device from which the entry data was obtained.
    var device: String? { get }
}

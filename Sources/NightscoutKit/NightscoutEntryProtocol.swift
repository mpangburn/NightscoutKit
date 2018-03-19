//
//  NightscoutEntryProtocol.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 3/18/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Foundation


/// A type fulfilling the role of a Nightscout blood glucose entry.
public protocol NightscoutEntryProtocol: UniquelyIdentifiable, BloodGlucoseUnitConvertible {
    /// Describes the source of a blood glucose entry.
    typealias Source = NightscoutEntrySource

    /// The entry's unique, internally assigned identifier.
    var id: String { get }

    /// The blood glucose value. Units are specified by the `units` property.
    var glucoseValue: Double { get }

    /// The blood glucose units in which the glucose value is measured.
    var units: BloodGlucoseUnit { get }

    /// The source of the blood glucose entry.
    var source: Source { get }

    /// The date at which the entry was recorded.
    var date: Date { get }

    /// The device from which the entry data was obtained.
    var device: String? { get }
}

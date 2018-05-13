//
//  BloodGlucoseUnitConvertible.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 3/23/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

/// A type that can convert between blood glucose units.
public protocol BloodGlucoseUnitConvertible {
    /// Returns an instance converted to the specified blood glucose units.
    /// - Parameter units: The blood glucose units to which to convert.
    /// - Returns: An instance converted to the specified blood glucose units.
    func converted(to units: BloodGlucoseUnit) -> Self

    /// Converts this instance to the specified blood glucose units.
    /// - Parameter units: The blood glucose units to which to convert.
    mutating func convert(to units: BloodGlucoseUnit)
}

// MARK: - Default Implementations

extension BloodGlucoseUnitConvertible {
    public mutating func convert(to units: BloodGlucoseUnit) {
        self = converted(to: units)
    }
}

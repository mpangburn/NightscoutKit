//
//  BloodGlucoseValue.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 3/21/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Foundation


/// Describes a blood glucose value and the units in which it is measured.
public struct BloodGlucoseValue: BloodGlucoseUnitConvertible, Hashable {
    /// The recorded glucose value.
    public let value: Double

    /// The units in which the glucose value is measured.
    public let units: BloodGlucoseUnit

    /// Creates a new blood glucose value.
    /// - Parameter value: The recorded glucose value.
    /// - Parameter units: The units in which the glucose value is measured.
    /// - Returns: A new blood glucose value with the specified units.
    public init(value: Double, units: BloodGlucoseUnit) {
        self.value = value
        self.units = units
    }

    /// Returns a glucose value converted to the specified units.
    /// - Parameter units: The blood glucose units to which to convert.
    /// - Returns: A glucose value converted to the specified units.
    public func converted(to units: BloodGlucoseUnit) -> BloodGlucoseValue {
        return BloodGlucoseValue(
            value: value * units.conversionFactor / self.units.conversionFactor,
            units: units
        )
    }

    /// Returns a string for the glucose value appropriate for the units in which it is measured.
    /// ```
    /// let mgdlGlucose = BloodGlucoseValue(value: 112.0, units: .milligramsPerDeciliter)
    /// print(mgdlGlucose.valueString) // prints 112
    ///
    /// let mmolGlucose = BloodGlucoseValue(value: 6.7, units: .millimolesPerLiter)
    /// print(mmolGlucose.valueString) // prints 6.7
    /// ```
    public var valueString: String {
        let format = "%.\(units.preferredFractionDigits)f"
        return String(format: format, value)
    }
}

// MARK: - CustomStringConvertible

extension BloodGlucoseValue: CustomStringConvertible {
    public var description: String {
        let format = NSLocalizedString(
            "QUANTITY_VALUE_AND_UNIT",
            value: "%1$@ %2$@",
            comment: "Format string for combining localized numeric value and unit. (1: numeric value)(2: unit)"
        )
        return String(format: format, valueString, units.description)
    }
}

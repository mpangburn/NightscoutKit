//
//  BloodGlucoseUnit.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 2/16/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

/// A type that can convert between blood glucose units.
public protocol BloodGlucoseUnitConvertible {
    /// Returns an instance converted to the specified blood glucose units.
    /// - Parameter units: The blood glucose units to which to convert.
    /// - Returns: An instance converted to the specified blood glucose units.
    func converted(toUnits units: BloodGlucoseUnit) -> Self
}

/// Represents a unit of concentration for measuring blood glucose.
public enum BloodGlucoseUnit: String {
    case milligramsPerDeciliter = "mg/dl"
    case millimolesPerLiter = "mmol"

    /// Returns the equivalent of the glucose value in the specified units.
    static func convert(_ glucoseValue: Double, from fromUnits: BloodGlucoseUnit, to toUnits: BloodGlucoseUnit) -> Double {
        return glucoseValue * toUnits.conversionFactor / fromUnits.conversionFactor
    }

    /// The preferred number of fraction digits for displaying a glucose value with these units.
    var preferredFractionDigits: Int {
        switch self {
        case .milligramsPerDeciliter:
            return 0
        case .millimolesPerLiter:
            return 1
        }
    }

    /// The conversion factor for converting from this unit to milligrams per deciliter (mg/dL).
    var conversionFactor: Double {
        switch self {
        case .milligramsPerDeciliter:
            return 1
        case .millimolesPerLiter:
            return 1 / 18
        }
    }
}

extension BloodGlucoseUnit: CustomStringConvertible {
    public var description: String {
        switch self {
        case .milligramsPerDeciliter:
            return "mg/dL"
        case .millimolesPerLiter:
            return "mmol/L"
        }
    }
}

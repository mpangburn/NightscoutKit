//
//  BloodGlucoseUnit.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 2/16/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Foundation

/// Represents a unit of concentration for measuring blood glucose.
public enum BloodGlucoseUnit: String {
    case milligramsPerDeciliter = "mg/dl"
    case millimolesPerLiter = "mmol"

    /// The conversion factor for converting from this unit to milligrams per deciliter (mg/dL).
    public var conversionFactor: Double {
        switch self {
        case .milligramsPerDeciliter:
            return 1
        case .millimolesPerLiter:
            return 1 / 18
        }
    }

    /// The preferred number of fraction digits for displaying a glucose value with these units.
    public var preferredFractionDigits: Int {
        switch self {
        case .milligramsPerDeciliter:
            return 0
        case .millimolesPerLiter:
            return 1
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

extension NumberFormatter {
    /// Returns a NumberFormatter for formatting blood glucose values using the given unit.
    /// - Parameter unit: The unit for which glucose values should be formatted.
    /// - Returns: A formatter for formatting blood glucose values using the given unit.
    public static func glucoseFormatter(for unit: BloodGlucoseUnit) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumIntegerDigits = 1
        formatter.minimumFractionDigits = unit.preferredFractionDigits
        formatter.maximumFractionDigits = unit.preferredFractionDigits
        return formatter
    }
}

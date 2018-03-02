//
//  BloodGlucoseUnit.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 2/16/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

public enum BloodGlucoseUnit: String {
    case milligramsPerDeciliter = "mg/dl"
    case millimolesPerLiter = "mmol"
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

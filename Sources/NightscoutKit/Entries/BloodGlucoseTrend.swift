//
//  BloodGlucoseTrend.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 2/19/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

/// Represents the rate of change of a blood glucose value.
public enum BloodGlucoseTrend: String, Codable {
    case doubleUp = "DoubleUp"
    case singleUp = "SingleUp"
    case fortyFiveUp = "FortyFiveUp"
    case flat = "Flat"
    case fortyFiveDown = "FortyFiveDown"
    case singleDown = "SingleDown"
    case doubleDown = "DoubleDown"
    case unknown = "NONE"

    /// A symbol representing the trend.
    /// ```
    /// let trend: BloodGlucoseTrend = .fortyFiveUp
    /// print(trend.symbol) // prints "↗"
    /// ```
    public var symbol: String {
        switch self {
        case .doubleUp:
            return "⇈"
        case .singleUp:
            return "↑"
        case .fortyFiveUp:
            return "↗"
        case .flat:
            return "→"
        case .fortyFiveDown:
            return "↘"
        case .singleDown:
            return "↓"
        case .doubleDown:
            return "⇊"
        case .unknown:
            return "-"
        }
    }
}

extension BloodGlucoseTrend: CustomStringConvertible {
    public var description: String {
        return symbol
    }
}

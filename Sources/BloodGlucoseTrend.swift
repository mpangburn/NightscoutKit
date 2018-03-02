//
//  BloodGlucoseTrend.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 2/19/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

public enum BloodGlucoseTrend: String {
    case doubleUp = "DoubleUp"
    case singleUp = "SingleUp"
    case fortyFiveUp = "FortyFiveUp"
    case flat = "Flat"
    case fortyFiveDown = "FortyFiveDown"
    case singleDown = "SingleDown"
    case doubleDown = "DoubleDown"
    case unknown

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

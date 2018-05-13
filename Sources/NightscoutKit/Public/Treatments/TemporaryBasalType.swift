//
//  TemporaryBasalType.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 5/5/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

/// The type of a temporary basal—either percentage or absolute.
public enum TemporaryBasalType: Hashable {
    case percentage(Int)
    case absolute(rate: Double)
}

// MARK: - JSON

extension TemporaryBasalType: JSONParseable {
    enum Key {
        static let percentage: JSONKey<Int> = "percent"
        static let absolute: JSONKey<Double> = "absolute"
    }

    static func parse(fromJSON treatmentJSON: JSONDictionary) -> TemporaryBasalType? {
        if let percentage = treatmentJSON[Key.percentage] {
            return .percentage(percentage)
        } else if let rate = treatmentJSON[Key.absolute] {
            return .absolute(rate: rate)
        } else {
            return nil
        }
    }
}

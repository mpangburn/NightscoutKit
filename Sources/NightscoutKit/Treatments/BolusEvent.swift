//
//  BolusEvent.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 5/12/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

/// The type of a bolus—either standard or combo (dual-wave).
public enum BolusEvent: Hashable {
    case standard(Bolus)
    case combo(ComboBolus)
}

// MARK: - JSON

extension BolusEvent: JSONParseable {
    static func parse(fromJSON treatmentJSON: JSONDictionary) -> BolusEvent? {
        if let bolus = Bolus.parse(fromJSON: treatmentJSON) {
            return .standard(bolus)
        } else if let comboBolus = ComboBolus.parse(fromJSON: treatmentJSON) {
            return .combo(comboBolus)
        } else {
            return nil
        }
    }
}

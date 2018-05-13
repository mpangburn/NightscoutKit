//
//  TemporaryBasalEvent.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 5/12/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

/// A temporary basal event—either `began` or `ended`.
public enum TemporaryBasalEvent: Hashable {
    case began(TemporaryBasal)
    case ended
}

// MARK: - JSON

extension TemporaryBasalEvent: JSONParseable {
    static func parse(fromJSON treatmentJSON: JSONDictionary) -> TemporaryBasalEvent? {
        // Since this function will never return `nil`, it should be called only once
        // the treatment JSON contains the event type string matching a temporary basal.
        if let temporaryBasal = TemporaryBasal.parse(fromJSON: treatmentJSON) {
            return .began(temporaryBasal)
        } else {
            return .ended
        }
    }
}

//
//  TemporaryBasal.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 5/5/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Foundation


/// Describes a temporary basal.
public struct TemporaryBasal: TemporaryBasalProtocol, Hashable {
    /// The start date of the temporary basal.
    public let startDate: Date

    /// The duration of the temporary basal.
    public let duration: TimeInterval

    /// The type of the temporary basal—either percentage or absolute.
    public let type: TemporaryBasalType

    /// Creates a new temporary basal.
    /// - Parameter startDate: The start date of the temporary basal.
    /// - Parameter duration: The duration of the temporary basal.
    /// - Parameter type: The type of the temporary basal—either percentage or absolute.
    /// - Returns: A new temporary basal.
    public init(startDate: Date, duration: TimeInterval, type: TemporaryBasalType) {
        self.startDate = startDate
        self.duration = duration
        self.type = type
    }
}

// MARK: - JSON

extension TemporaryBasal: JSONParseable {
    enum Key {
        static let percentage: JSONKey<Int> = "percent"
        static let absolute: JSONKey<Double> = "absolute"
    }

    static func parse(fromJSON treatmentJSON: JSONDictionary) -> TemporaryBasal? {
        guard
            let type = TemporaryBasalType.parse(fromJSON: treatmentJSON),
            let startDate = treatmentJSON[convertingDateFrom: NightscoutTreatment.Key.dateString],
            let duration = treatmentJSON[NightscoutTreatment.Key.durationInMinutes].map(TimeInterval.minutes)
        else {
            return nil
        }

        return TemporaryBasal(startDate: startDate, duration: duration, type: type)
    }
}

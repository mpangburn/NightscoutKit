//
//  ComboBolus.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 5/4/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Foundation


/// A dual-wave bolus in which some insulin is delivered immediately,
/// and some is delivered over the course of some time interval.
public struct ComboBolus: TimelinePeriod, Hashable, Codable {
    /// The delivery date of the bolus.
    public let startDate: Date

    /// The period of time over which the remainder of the insulin is delivered.
    public let duration: TimeInterval

    /// The total amount of insulin delivered in units (U).
    public let totalInsulin: Double

    /// The percentage of the bolus delivered up front.
    /// This value is an integer in the range 0...100.
    public let percentageDeliveredUpFront: Int

    /// The percentage of insulin distributed over the duration of the combo bolus.
    /// This value is an integer in the range 0...100.
    public var percentageDistributedOverTime: Int {
        return 100 - percentageDeliveredUpFront
    }

    /// The amount of insulin delivered up front in units (U).
    public var insulinDeliveredUpFront: Double {
        return totalInsulin * Double(percentageDeliveredUpFront) / 100
    }

    /// The amount of insulin delivered over the period of `extendedDeliveryDuration`.
    public var insulinDistributedOverTime: Double {
        return totalInsulin - insulinDeliveredUpFront
    }

    /// The rate at which the insulin distributed over time is delivered in units per minute (U/min).
    public var rateOfInsulinDelivery: Double {
        return insulinDistributedOverTime / duration.minutes
    }

    /// Creates a new combo bolus.
    /// - Parameter totalInsulin: The total amount of insulin delivered in units (U).
    /// - Parameter percentageUpFront: The percentage of the bolus delivered up front. This value must fall in the range 0...100.
    /// - Returns: A new combo bolus.
    public init(startDate: Date, duration: TimeInterval, totalInsulin: Double, percentageDeliveredUpFront: Int) {
        precondition(0...100 ~= percentageDeliveredUpFront, "The percentage of insulin delivered up front must fall in the range 0...100.")
        self.startDate = startDate
        self.duration = duration
        self.totalInsulin = totalInsulin
        self.percentageDeliveredUpFront = percentageDeliveredUpFront
    }

    /// Returns the amount of the bolus insulin delivered at the given date.
    /// - Parameter date: The date at which to compute the amount of delivered insulin. Defaults to the current date.
    /// - Returns: The amount of the bolus insulin delivered at the given date.
    public func insulinDelivered(at date: Date = Date()) -> Double {
        if date < startDate {
            return 0
        } else if date > endDate {
            return totalInsulin
        } else {
            let percentageOfTimePassed = date.timeIntervalSince(startDate) / duration
            let distributedInsulinGiven = percentageOfTimePassed * insulinDistributedOverTime
            return insulinDeliveredUpFront + distributedInsulinGiven
        }
    }
}

// MARK: - JSON

extension ComboBolus: JSONParseable {
    enum Key {
        static let totalInsulinString: JSONKey<String> = "enteredinsulin"
        static let percentageDeliveredUpFrontString: JSONKey<String> = "splitNow"
        static let percentageDistributedOverTimeString: JSONKey<String> = "splitExt"
    }

    static func parse(fromJSON treatmentJSON: JSONDictionary) -> ComboBolus? {
        guard
            let date = treatmentJSON[convertingDateFrom: NightscoutTreatment.Key.dateString],
            let duration = treatmentJSON[NightscoutTreatment.Key.durationInMinutes].map(TimeInterval.minutes),
            duration > 0,
            let totalInsulin = treatmentJSON[Key.totalInsulinString].flatMap(Double.init),
            let percentageDeliveredUpFront = treatmentJSON[Key.percentageDeliveredUpFrontString].flatMap(Int.init),
            0...100 ~= percentageDeliveredUpFront
        else {
            return nil
        }

        return .init(startDate: date, duration: duration, totalInsulin: totalInsulin, percentageDeliveredUpFront: percentageDeliveredUpFront)
    }
}

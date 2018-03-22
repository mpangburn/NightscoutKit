//
//  PredictedBloodGlucoseValue.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 3/14/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Foundation


// Describes a predicted blood glucose value.
public struct PredictedBloodGlucoseValue: BloodGlucoseUnitConvertible {
    /// The predicted glucose value.
    public let glucoseValue: BloodGlucoseValue

    /// The date at which the glucose value is predicted.
    public let date: Date

    /// Returns the predicted glucose value converted to the specified units.
    /// - Parameter units: The blood glucose units to which to convert.
    /// - Returns: A predicted glucose value converted to the specified units.
    public func converted(to units: BloodGlucoseUnit) -> PredictedBloodGlucoseValue {
        return PredictedBloodGlucoseValue(
            glucoseValue: glucoseValue.converted(to: units),
            date: date
        )
    }
}

extension Array where Element == PredictedBloodGlucoseValue {
    init(values: [Int], everyFiveMinutesBeginningAt startDate: Date) {
        self = values.enumerated().map { index, value in
            let predictionDate = startDate + .minutes(5 * Double(index))
            return PredictedBloodGlucoseValue(
                glucoseValue: BloodGlucoseValue(value: Double(value), units: .milligramsPerDeciliter),
                date: predictionDate
            )
        }
    }
}

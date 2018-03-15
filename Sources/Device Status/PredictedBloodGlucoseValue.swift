//
//  PredictedBloodGlucoseValue.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 3/14/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

// Describes a predicted blood glucose value.
public struct PredictedBloodGlucoseValue {
    /// The predicted glucose value in milligrams per deciliter (mg/dL).
    public let value: Int

    /// The date at which the glucose value is predicted.
    public let date: Date
}

extension Array where Element == PredictedBloodGlucoseValue {
    init(values: [Int], everyFiveMinutesBeginningAt startDate: Date) {
        self = values.enumerated().map { index, value in
            let predictionDate = startDate + .minutes(5 * Double(index))
            return PredictedBloodGlucoseValue(value: value, date: predictionDate)
        }
    }
}

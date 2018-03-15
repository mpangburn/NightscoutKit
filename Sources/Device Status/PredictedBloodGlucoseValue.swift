//
//  PredictedBloodGlucoseValue.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 3/14/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

public struct PredictedBloodGlucoseValue {
    public let mgdlValue: Int
    public let date: Date
}

extension Array where Element == PredictedBloodGlucoseValue {
    init(mgdlValues: [Int], everyFiveMinutesBeginningAt startDate: Date) {
        self = mgdlValues.enumerated().map { index, value in
            let predictionDate = startDate + .minutes(5 * Double(index))
            return PredictedBloodGlucoseValue(mgdlValue: value, date: predictionDate)
        }
    }
}

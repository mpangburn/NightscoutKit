//
//  AnyClosedLoopStatus.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 3/14/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Foundation


/// A type-erased closed loop status.
public struct AnyClosedLoopStatus: ClosedLoopStatusProtocol {
    public struct InsulinOnBoardStatus: InsulinOnBoardStatusProtocol {
        public let timestamp: Date
        public let insulinOnBoard: Double?
        public let basalInsulinOnBoard: Double?
    }

    public struct TemporaryBasal: TemporaryBasalProtocol {
        public let startDate: Date
        public let rate: Double
        public let duration: TimeInterval
    }

    public let timestamp: Date
    public let insulinOnBoardStatus: InsulinOnBoardStatus?
    public let carbsOnBoard: Int?
    public let enactedTemporaryBasal: TemporaryBasal?
    public let recommendedTemporaryBasal: TemporaryBasal?
    public let predictedBloodGlucoseCurves: [[PredictedBloodGlucoseValue]]?

    init<T: ClosedLoopStatusProtocol>(_ closedLoopStatus: T) {
        self.timestamp = closedLoopStatus.timestamp
        self.insulinOnBoardStatus = closedLoopStatus.insulinOnBoardStatus.map {
            InsulinOnBoardStatus(timestamp: $0.timestamp, insulinOnBoard: $0.insulinOnBoard, basalInsulinOnBoard: $0.basalInsulinOnBoard)
        }
        self.carbsOnBoard = closedLoopStatus.carbsOnBoard
        self.enactedTemporaryBasal = closedLoopStatus.enactedTemporaryBasal.map {
            TemporaryBasal(startDate: $0.startDate, rate: $0.rate, duration: $0.duration)
        }
        self.recommendedTemporaryBasal = closedLoopStatus.recommendedTemporaryBasal.map {
            TemporaryBasal(startDate: $0.startDate, rate: $0.rate, duration: $0.duration)
        }
        self.predictedBloodGlucoseCurves = closedLoopStatus.predictedBloodGlucoseCurves
    }
}

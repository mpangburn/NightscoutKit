//
//  ClosedLoopStatusProtocol.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 3/14/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

public protocol ClosedLoopStatusProtocol {
    associatedtype InsulinOnBoardStatus: InsulinOnBoardStatusProtocol
    associatedtype TemporaryBasal: TemporaryBasalProtocol

    var timestamp: Date { get }
    var insulinOnBoardStatus: InsulinOnBoardStatus? { get }
    var carbsOnBoard: Int? { get }
    var enactedTemporaryBasal: TemporaryBasal? { get }
    var recommendedTemporaryBasal: TemporaryBasal? { get }
    var predictedBloodGlucoseCurves: [[PredictedBloodGlucoseValue]]? { get }
}

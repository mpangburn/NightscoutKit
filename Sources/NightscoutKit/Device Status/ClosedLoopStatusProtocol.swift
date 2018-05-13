//
//  ClosedLoopStatusProtocol.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 3/14/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Foundation


/// A type describing the status of a closed loop.
public protocol ClosedLoopStatusProtocol {
    /// Describes the status of insulin on board.
    associatedtype InsulinOnBoardStatus: InsulinOnBoardStatusProtocol

    /// Describes the temporary basals enacted by the closed loop.
    associatedtype TemporaryBasal: AbsoluteTemporaryBasalProtocol

    /// The date at which the status was recorded.
    var timestamp: Date { get }

    /// The status of the insulin on board (IOB).
    var insulinOnBoardStatus: InsulinOnBoardStatus? { get }

    /// The carbs on board in grams (g).
    var carbsOnBoard: Int? { get }

    /// The enacted temporary basal.
    var enactedTemporaryBasal: TemporaryBasal? { get }

    /// The temporary basal recommended by the loop.
    var recommendedTemporaryBasal: TemporaryBasal? { get }

    /// An array of predicted glucose value curves based on currently available data.
    var predictedBloodGlucoseCurves: [[PredictedBloodGlucoseValue]]? { get }
}

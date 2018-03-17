//
//  InsulinOnBoardStatusProtocol.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 3/14/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Foundation


/// A type describing the status of insulin on board.
public protocol InsulinOnBoardStatusProtocol {
    /// The date at which the status of the insulin on board was recorded.
    var timestamp: Date { get }

    /// The total insulin on board in units (U),
    /// equal to the sum of the basal and bolus insulin on board.
    var insulinOnBoard: Double? { get }

    /// The basal insulin on board in units (U).
    var basalInsulinOnBoard: Double? { get }

    /// The bolus insulin on board in units (U).
    var bolusInsulinOnBoard: Double? { get }
}

extension InsulinOnBoardStatusProtocol {
    public var bolusInsulinOnBoard: Double? {
        guard let insulinOnBoard = insulinOnBoard, let basalInsulinOnBoard = basalInsulinOnBoard else {
            return nil
        }
        return insulinOnBoard - basalInsulinOnBoard
    }
}

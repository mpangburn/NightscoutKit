//
//  InsulinOnBoardStatusProtocol.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 3/14/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

public protocol InsulinOnBoardStatusProtocol {
    var timestamp: Date { get }
    var insulinOnBoard: Double? { get }
    var basalInsulinOnBoard: Double? { get }
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

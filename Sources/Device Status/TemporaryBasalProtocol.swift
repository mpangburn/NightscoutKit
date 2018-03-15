//
//  TemporaryBasalProtocol.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 3/14/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

public protocol TemporaryBasalProtocol {
    var startDate: Date { get }
    var rate: Double { get }
    var duration: TimeInterval { get }
}

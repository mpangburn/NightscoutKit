//
//  TemporaryBasalProtocol.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 3/14/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

/// A type describing a temporary basal.
public protocol TemporaryBasalProtocol: TimelinePeriod {
    /// The type of the temporary basal—either percentage or absolute.
    var type: TemporaryBasalType { get }
}

/// A type describing an absolute temporary basal.
public protocol AbsoluteTemporaryBasalProtocol: TemporaryBasalProtocol {
    /// The basal rate in units per hour (U/hr).
    var rate: Double { get }
}

extension AbsoluteTemporaryBasalProtocol {
    /// The type of the temporary basal. For a type conforming to `AbsoluteTemporaryBasalProtocol`, the value of this property is always `absolute`.
    public var type: TemporaryBasalType {
        return .absolute(rate: rate)
    }
}

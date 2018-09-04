//
//  PartiallyRawRepresentable.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 2/18/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

/// A type that can be converted to and from a raw value in simple cases.
internal protocol PartiallyRawRepresentable {
    associatedtype SimpleRawValue
    static var simpleCases: [Self] { get }
    var simpleRawValue: SimpleRawValue { get }
}

extension PartiallyRawRepresentable where SimpleRawValue: Equatable {
    init?(simpleRawValue: SimpleRawValue) {
        for (simpleCase, simpleRaw) in zip(Self.simpleCases, Self.simpleCases.map { $0.simpleRawValue }) {
            if simpleRaw == simpleRawValue {
                self = simpleCase
                return
            }
        }

        return nil
    }
}

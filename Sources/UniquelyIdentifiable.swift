//
//  UniquelyIdentifiable.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 2/23/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

/// A type that can be uniquely identified by a string.
public protocol UniquelyIdentifiable: Hashable {
    /// A string that uniquely identifies the instance.
    var id: String { get }
}

extension UniquelyIdentifiable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }

    public var hashValue: Int {
        return id.hashValue
    }
}

//
//  UniquelyIdentifiable.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 2/23/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Foundation


/// A type that can be uniquely identified by an id string.
public protocol UniquelyIdentifiable: Hashable {
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

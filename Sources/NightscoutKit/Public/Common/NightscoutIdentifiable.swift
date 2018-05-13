//
//  NightscoutIdentifiable.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 5/10/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

/// A type that can be uniquely identified by Nightscout.
public protocol NightscoutIdentifiable: Hashable {
    /// The identifier uniquely identifying the instance.
    var id: NightscoutIdentifier { get }
}

extension NightscoutIdentifiable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }

    public var hashValue: Int {
        return id.hashValue
    }
}

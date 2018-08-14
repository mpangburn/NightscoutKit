//
//  DataConvertible.swift
//  NightscoutKitTests
//
//  Created by Michael Pangburn on 3/6/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Foundation


/// A type that can be parsed from data.
internal protocol DataParseable {
    static func parse(fromData data: Data) throws -> Self?
}

/// A type that can be represented as data.
internal protocol DataRepresentable {
    func data() throws -> Data
}

/// A type that can be converted to and from data.
internal typealias DataConvertible = DataParseable & DataRepresentable

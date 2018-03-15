//
//  DataConvertible.swift
//  NightscoutKitTests
//
//  Created by Michael Pangburn on 3/6/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

/// A type that can be parsed from data.
protocol DataParseable {
    static func parse(fromData data: Data) throws -> Self?
}

/// A type that can be represented as data.
protocol DataRepresentable {
    func data() throws -> Data
}

/// A type that can be converted to and from data.
typealias DataConvertible = DataParseable & DataRepresentable

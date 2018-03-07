//
//  StringParseable.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 2/23/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

/// A type that can be parsed from a string.
protocol StringParseable {
    init?(_ string: String)
}

extension Int: StringParseable { }
extension Int8: StringParseable { }
extension Int16: StringParseable { }
extension Int32: StringParseable { }
extension Int64: StringParseable { }

extension UInt: StringParseable { }
extension UInt8: StringParseable { }
extension UInt16: StringParseable { }
extension UInt32: StringParseable { }
extension UInt64: StringParseable { }

extension Double: StringParseable { }
extension Float: StringParseable { }
extension Float80: StringParseable { }

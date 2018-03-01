//
//  XCTestCase.swift
//  NightscoutKitTests
//
//  Created by Michael Pangburn on 2/18/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import XCTest


extension XCTestCase {
    public var bundle: Bundle {
        return Bundle(for: type(of: self))
    }

    public func loadFixture<T>(_ resourceName: String) -> T {
        let path = bundle.path(forResource: resourceName, ofType: "json")!
        return try! JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: path)), options: []) as! T
    }
}

//
//  XCTestCase.swift
//  NightscoutKitTests
//
//  Created by Michael Pangburn on 2/18/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import XCTest


extension XCTestCase {
    var bundle: Bundle {
        return Bundle(for: type(of: self))
    }

    func loadFixture<T>(_ resourceName: String) -> T {
        let path = bundle.path(forResource: resourceName, ofType: "json")!
        return try! JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: path)), options: []) as! T
    }

    func loadString(from resource: String) -> String? {
        guard let path = bundle.path(forResource: resource, ofType: nil),
            let contents = try? String(contentsOf: URL(fileURLWithPath: path)) else {
                return nil
        }

        return contents.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

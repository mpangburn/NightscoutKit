//
//  NightscoutKitTests.swift
//  NightscoutKitTests
//
//  Created by Michael Pangburn on 2/16/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import XCTest
@testable import NightscoutKit


class NightscoutKitTests: XCTestCase {
    func testParseTreatmentJSON() {
        let treatmentsJSON: [JSONDictionary] = loadFixture("treatments")
        let treatments = treatmentsJSON.flatMap(Treatment.init(rawValue:))
        XCTAssert(treatments.count == treatmentsJSON.count)
    }

    func testParseEntryJSON() {
        let entriesJSON: [JSONDictionary] = loadFixture("entries")
        let entries = entriesJSON.flatMap(BloodGlucoseEntry.init(rawValue:))
        XCTAssert(entries.count == entriesJSON.count)
    }

    func testParseProfileJSON() {
        let profileJSON: [JSONDictionary] = loadFixture("profile")
        let profileStores = profileJSON.flatMap(ProfileStoreSnapshot.parse)
        XCTAssert(profileJSON.count == profileStores.count)
    }
}


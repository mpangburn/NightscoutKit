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
    func testParseIndividualEntry() {
        let entryJSON: JSONDictionary = [
            "_id": "5a8a0764dc13514404097ed7",
            "date": 1518995177000,
            "dateString": "2018-02-18T23:06:17.000Z",
            "device": "share2",
            "direction": "Flat",
            "sgv": 145,
            "trend": 4,
            "type": "sgv"
        ]

        let entry = NightscoutEntry(rawValue: entryJSON)!

        let expectedEntry = NightscoutEntry(
            id: "5a8a0764dc13514404097ed7",
            glucoseValue: 145,
            source: .sensor(trend: .flat),
            date: TimeFormatter.date(from: "2018-02-18T23:06:17.000Z")!,
            device: "share2"
        )

        XCTAssert(entry.id == expectedEntry.id)
        XCTAssert(entry.glucoseValue == expectedEntry.glucoseValue)
        XCTAssert({
            switch (entry.source, expectedEntry.source) {
            case (.sensor(trend: .flat), .sensor(trend: .flat)):
                return true
            default:
                return false
            }
        }())
        XCTAssert(entry.date == expectedEntry.date)
        XCTAssert(entry.device == expectedEntry.device)
    }

    func testParseEntryJSON() {
        let entriesJSON: [JSONDictionary] = loadFixture("entries")
        let entries = entriesJSON.flatMap(NightscoutEntry.init(rawValue:))
        XCTAssert(entries.count == entriesJSON.count)
    }

    func testParseIndividualTreatment() {
        let treatmentJSON: JSONDictionary = [
            "_id": "5a89f9fcdc13514404093e3f",
            "absorptionTime": 180,
            "carbs": 25,
            "created_at": "2018-02-18T22:25:01Z",
            "enteredBy": "loop://Michael's iPhone",
            "eventType": "Meal Bolus",
            "insulin": "",
            "timestamp": "2018-02-18T22:25:01Z"
        ]

        let treatment = NightscoutTreatment(rawValue: treatmentJSON)!

        let expectedTreatment = NightscoutTreatment(
            id: "5a89f9fcdc13514404093e3f",
            eventType: .bolus(type: .meal),
            date: TimeFormatter.date(from: "2018-02-18T22:25:01Z")!,
            duration: 0,
            glucose: nil,
            insulinGiven: nil,
            carbsConsumed: 25,
            creator: "loop://Michael's iPhone",
            notes: ""
        )

        XCTAssert(treatment.id == expectedTreatment.id)
        XCTAssert({
            switch (treatment.eventType, expectedTreatment.eventType) {
            case (.bolus(type: .meal), .bolus(type: .meal)):
                return true
            default:
                return false
            }
        }())
        XCTAssert(treatment.date == expectedTreatment.date)
        XCTAssert(treatment.duration == expectedTreatment.duration)
        XCTAssert(treatment.glucose == expectedTreatment.glucose)
        XCTAssert(treatment.insulinGiven == expectedTreatment.insulinGiven)
        XCTAssert(treatment.carbsConsumed == expectedTreatment.carbsConsumed)
        XCTAssert(treatment.creator == expectedTreatment.creator)
        XCTAssert(treatment.notes == expectedTreatment.notes)
    }

    func testParseTreatmentJSON() {
        let treatmentsJSON: [JSONDictionary] = loadFixture("treatments")
        let treatments = treatmentsJSON.flatMap(NightscoutTreatment.init(rawValue:))
        XCTAssert(treatments.count == treatmentsJSON.count)

        for treatment in treatments {
            if case .unknown(let description) = treatment.eventType {
                XCTFail("Unknown event type \"\(description)\" found in well-formed data")
            }
        }
    }

    func testParseProfileRecordJSON() {
        let profileJSON: [JSONDictionary] = loadFixture("profiles")
        let profileStores = profileJSON.flatMap(NightscoutProfileRecord.parse)
        XCTAssert(profileJSON.count == profileStores.count)
    }

    func testParseOpenAPSStatusJSON1000Count() {
        let openAPSStatusJSON: [JSONDictionary] = loadFixture("openapsstatus")
        let deviceStatuses = openAPSStatusJSON.flatMap(NightscoutDeviceStatus.parse(fromJSON:))
        XCTAssert(openAPSStatusJSON.count == deviceStatuses.count)
    }
}


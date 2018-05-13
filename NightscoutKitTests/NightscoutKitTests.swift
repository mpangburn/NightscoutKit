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
            id: .init("5a8a0764dc13514404097ed7"),
            glucoseValue: BloodGlucoseValue(value: 145, units: .milligramsPerDeciliter),
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
        let entries = entriesJSON.compactMap(NightscoutEntry.init(rawValue:))
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
            "insulin": 3.5,
            "timestamp": "2018-02-18T22:25:01Z"
        ]

        let treatment = NightscoutTreatment(rawValue: treatmentJSON)!

        let date = TimeFormatter.date(from: "2018-02-18T22:25:01Z")!
        let insulinGiven = 3.5
        let expectedTreatment = NightscoutTreatment(
            id: .init("5a89f9fcdc13514404093e3f"),
            eventType: .bolus(.standard(Bolus(date: date, amount: insulinGiven, context: .meal))),
            date: date,
            glucose: nil,
            insulinGiven: insulinGiven,
            carbsConsumed: 25,
            recorder: "loop://Michael's iPhone",
            notes: nil
        )

        XCTAssert(treatment.id == expectedTreatment.id)
        XCTAssert(treatment.eventType == expectedTreatment.eventType)
        XCTAssert(treatment.date == expectedTreatment.date)
        XCTAssert(treatment.duration == expectedTreatment.duration)
        XCTAssert(treatment.glucose?.glucoseValue == expectedTreatment.glucose?.glucoseValue
            && treatment.glucose?.source == expectedTreatment.glucose?.source)
        XCTAssert(treatment.insulinGiven == expectedTreatment.insulinGiven)
        XCTAssert(treatment.carbsConsumed == expectedTreatment.carbsConsumed)
        XCTAssert(treatment.recorder == expectedTreatment.recorder)
        XCTAssert(treatment.notes == expectedTreatment.notes)
    }

    func testParseTreatmentJSON() {
        let treatmentsJSON: [JSONDictionary] = loadFixture("treatments")
        let treatments = treatmentsJSON.compactMap(NightscoutTreatment.init(rawValue:))
        // Count difference:
        // -1: Sample blood glucose entry with no glucose value
        XCTAssert(treatments.count == treatmentsJSON.count - 1)
        for treatment in treatments {
            if case .unknown(let description) = treatment.eventType {
                XCTFail("Unknown event type \"\(description)\" found in well-formed data")
            }
        }
    }

    func testParseProfileRecordJSON() {
        let profileJSON: [JSONDictionary] = loadFixture("profiles")
        let profileStores = profileJSON.compactMap(NightscoutProfileRecord.parse)
        XCTAssert(profileJSON.count == profileStores.count)
    }

    func testParseLoopDeviceStatusJSON1000Count() {
        let loopDeviceStatusJSON: [JSONDictionary] = loadFixture("loopdevicestatus")
        let deviceStatuses = loopDeviceStatusJSON.compactMap(NightscoutDeviceStatus.parse(fromJSON:))
        XCTAssert(loopDeviceStatusJSON.count == deviceStatuses.count)
    }

    func testParseOpenAPSDeviceStatusJSON1000Count() {
        let openAPSDeviceStatusJSON: [JSONDictionary] = loadFixture("openapsstatus")
        let deviceStatuses = openAPSDeviceStatusJSON.compactMap(NightscoutDeviceStatus.parse(fromJSON:))
        XCTAssert(openAPSDeviceStatusJSON.count == deviceStatuses.count)
    }
}


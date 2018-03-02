//
//  NightscoutKitLiveTests.swift
//  NightscoutKitTests
//
//  Created by Michael Pangburn on 3/1/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import XCTest
@testable import NightscoutKit


/// These tests are used for loading Nightscout data from my personal URL.
/// My URL is untracked by git, so these tests are ignored if the file "myNightscoutURL" does not exist.
class NightscoutKitLiveTests: XCTestCase {
    func testHTTPRequest() {
        guard let nightscoutURLString = loadNightscoutURL(),
            let nightscout = try? Nightscout(baseURL: nightscoutURLString) else {
                return
        }

        let settingsExpectation = expectation(description: "Settings response")
        nightscout.fetchSettings { result in
            switch result {
            case .success(let settings):
                print("===== SETTINGS =====")
                print(settings)
                print()
            case .failure(let error):
                print(error)
            }
            settingsExpectation.fulfill()
        }

        let entriesExpectation = expectation(description: "Entries response")
        nightscout.fetchEntries { result in
            switch result {
            case .success(let entries):
                print("===== ENTRIES =====")
                entries.forEach { print($0) }
                print()
            case .failure(let error):
                print(error)
            }
            entriesExpectation.fulfill()
        }

        let treatmentsExpectation = expectation(description: "Treatments response")
        nightscout.fetchTreatments { result in
            switch result {
            case .success(let treatments):
                print("===== TREATMENTS =====")
                treatments.forEach { print($0) }
                print()
            case .failure(let error):
                print(error)
            }
            treatmentsExpectation.fulfill()
        }

        let profileStoresExpectation = expectation(description: "Profile stores response")
        nightscout.fetchProfileStoreSnapshots { result in
            switch result {
            case .success(let profileStores):
                print("===== PROFILE STORES =====")
                profileStores.forEach { print($0) }
                print()
            case .failure(let error):
                print(error)
            }
            profileStoresExpectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

}

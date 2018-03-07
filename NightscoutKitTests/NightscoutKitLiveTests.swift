//
//  NightscoutKitLiveTests.swift
//  NightscoutKitTests
//
//  Created by Michael Pangburn on 3/1/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import XCTest
@testable import NightscoutKit


/// These tests interact with Nightscout data from my personal site.
/// My URL and API secret are untracked by git, so these tests are ignored if the files containing them do not exist.
class NightscoutKitLiveTests: XCTestCase {
    lazy var nightscout: Nightscout? = {
        guard let urlString = loadString(from: "nightscouturl"), let apiSecret = loadString(from: "apisecret") else {
            return nil
        }
        return try? Nightscout(baseURLString: urlString, apiSecret: apiSecret)
    }()

    func testFetchSnapshot() {
        guard let nightscout = nightscout else { return }

        let snapshotExpectation = expectation(description: "Nightscout snapshot")
        nightscout.snapshot { result in
            switch result {
            case .success(let snapshot):
                print(snapshot)
            case .failure(let error):
                print(error)
            }

            snapshotExpectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testAuthorization() {
        guard let nightscout = nightscout else { return }

        let authorizationExpectation = expectation(description: "Authorization")
        nightscout.verifyAuthorization { error in
            if let error = error {
                print(error)
            }
            authorizationExpectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testLive() {
//        guard let nightscout = nightscout else { return }
    }
}

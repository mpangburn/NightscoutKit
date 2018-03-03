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
}

//
//  NightscoutCredentials.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 5/13/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Foundation


public struct NightscoutCredentials: Equatable, Codable {
    public let url: URL
    public let apiSecret: String?

    public static func verify(url: URL, apiSecret: String? = nil, completion: @escaping (NightscoutResult<NightscoutCredentials>) -> Void) {
        let credentials = NightscoutCredentials(url: url, apiSecret: apiSecret)
        let testNightscout = Nightscout(credentials: credentials)
        // Verify URL by fetching a single entry
        testNightscout.fetchMostRecentEntries(count: 1) { result in
            switch result {
            case .success(_):
                if apiSecret != nil {
                    testNightscout.verifyAuthorization { error in
                        if let error = error {
                            completion(.failure(error))
                        } else {
                            completion(.success(credentials))
                        }
                    }
                } else {
                    // No API secret validation requested
                    completion(.success(credentials))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

extension NightscoutCredentials: Hashable {
    public var hashValue: Int {
        // TODO: better hashing here
        var hash = url.hashValue
        if let apiSecret = apiSecret {
            hash ^= apiSecret.hashValue
        }
        return hash
    }
}

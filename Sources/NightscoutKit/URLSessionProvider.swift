//
//  URLSessionProvider.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 6/25/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Foundation


internal final class URLSessionProvider {
    private var sessions: [NightscoutAPIEndpoint: URLSession] = [:]

    func urlSession(for endpoint: NightscoutAPIEndpoint) -> URLSession {
        if let session = sessions[endpoint] {
            return session
        } else {
            let session = URLSession(configuration: .default)
            sessions[endpoint] = session
            return session
        }
    }
}

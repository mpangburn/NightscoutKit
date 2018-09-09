//
//  URLSessionProvider.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 6/25/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Foundation
import Oxygen


internal typealias URLSessionProvider = CacheMap<NightscoutAPIEndpoint, URLSession>

extension /* URLSessionProvider */ CacheMap where Input == NightscoutAPIEndpoint, Output == URLSession {
    internal convenience init() {
        self.init(new(URLSession(configuration: .default)))
    }
}

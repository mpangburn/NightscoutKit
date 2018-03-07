//
//  URL.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 2/18/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

extension URL {
    func appendingPathComponents(_ pathComponents: String...) -> URL {
        var base = self
        pathComponents.forEach { base.appendPathComponent($0) }
        return base
    }

    var components: URLComponents? {
        return URLComponents(url: self, resolvingAgainstBaseURL: true)
    }
}

extension URLComponents {
    func addingQueryItems(_ queryItems: [URLQueryItem]) -> URLComponents {
        var copy = self
        queryItems.forEach { copy.addQueryItem($0) }
        return copy
    }

    mutating func addQueryItem(_ queryItem: URLQueryItem) {
        queryItems = (queryItems ?? []).appending(queryItem)
    }
}

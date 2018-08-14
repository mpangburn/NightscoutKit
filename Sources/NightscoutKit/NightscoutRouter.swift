//
//  NightscoutRouter.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 5/13/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Foundation


internal struct NightscoutRouter {
    private let url: URL
    private let apiSecret: String?

    init(url: URL, apiSecret: String? = nil) {
        self.url = url
        self.apiSecret = apiSecret
    }
}

extension NightscoutRouter {
    private static let apiVersion = "v1"

    private func route(to endpoint: NightscoutAPIEndpoint, queryItems: [NightscoutQueryItem] = []) -> URL? {
        let base = url.appendingPathComponents("api", NightscoutRouter.apiVersion, endpoint.rawValue)
        let urlQueryItems = queryItems.map { $0.urlQueryItem }
        return base.components?.addingQueryItems(urlQueryItems).url
    }

    func configureURLRequest(for endpoint: NightscoutAPIEndpoint, queryItems: [NightscoutQueryItem] = [], httpMethod: HTTPMethod? = nil) -> URLRequest? {
        guard let url = route(to: endpoint, queryItems: queryItems) else {
            return nil
        }

        var request = URLRequest(url: url)
        var headers = [
            "Content-Type": "application/json",
            "Accept": "application/json",
        ]

        if let apiSecret = apiSecret {
            headers["api-secret"] = apiSecret.sha1()
        }

        headers.forEach { header, value in request.setValue(value, forHTTPHeaderField: header) }
        request.httpMethod = httpMethod?.rawValue

        return request
    }
}

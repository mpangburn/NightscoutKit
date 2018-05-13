//
//  NightscoutRouter.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 5/13/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Foundation


struct NightscoutRouter {
    let credentials: NightscoutCredentials
}

extension NightscoutRouter {
    private static let apiVersion = "v1"

    private func route(to endpoint: NightscoutAPIEndpoint, queryItems: [NightscoutQueryItem] = []) -> URL? {
        let base = credentials.url.appendingPathComponents("api", NightscoutRouter.apiVersion, endpoint.rawValue)
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

        if let apiSecret = credentials.apiSecret {
            headers["api-secret"] = apiSecret.sha1()
        }

        headers.forEach { header, value in request.setValue(value, forHTTPHeaderField: header) }
        request.httpMethod = httpMethod?.rawValue

        return request
    }
}

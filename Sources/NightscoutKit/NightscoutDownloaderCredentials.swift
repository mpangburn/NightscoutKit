//
//  NightscoutDownloaderCredentials.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 6/25/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Foundation
import Oxygen


/// Represents validated credentials to download data from a Nightscout site.
public struct NightscoutDownloaderCredentials: Hashable, Codable {
    /// The Nightscout site URL.
    public let url: URL

    /// The Nightscout site API secret.
    public let apiSecret: String

    /// Validates a Nightscout site URL.
    /// - Parameter url: The Nightscout site URL to validate.
    /// - Parameter completion: The completion handler for the result of the validation request.
    /// - Parameter result: The result of the validation. In the case of success, this result will contain a valid credentials instance.
    public static func validate(
        url: URL,
        apiSecret: String,
        completion: @escaping (_ result: NightscoutResult<NightscoutDownloaderCredentials>) -> Void
    ) {
        let credentials = NightscoutDownloaderCredentials(url: url, apiSecret: apiSecret)
        let testDownloader = NightscoutDownloader(credentials: credentials)
        // Verify URL by fetching a single entry.
        testDownloader.fetchMostRecentEntries(count: 1) { result in
            completion(result.map(always(credentials)))
        }
    }
}

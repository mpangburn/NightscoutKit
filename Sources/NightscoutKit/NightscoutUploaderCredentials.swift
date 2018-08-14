//
//  NightscoutUploaderCredentials.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 7/16/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Foundation


/// Represents validated credentials to upload, update, and delete data to/from a Nightscout site.
public struct NightscoutUploaderCredentials: Hashable, Codable {
    /// The Nightscout site URL.
    public let url: URL

    /// The Nightscout site API secret.
    public let apiSecret: String

    /// Validates a given API secret using the already-verified downloader credentials.
    /// - Parameter downloaderCredentials: Validated credentials for a Nightscout site URL.
    /// - Parameter apiSecret: The API secret to validate.
    /// - Parameter completion: The completion handler for the result of the validation request.
    /// - Parameter result: The result of the validation. In the case of success, this result will contain a valid credentials instance.
    public static func validate(
        downloaderCredentials: NightscoutDownloaderCredentials,
        apiSecret: String,
        completion: @escaping (_ result: NightscoutResult<NightscoutUploaderCredentials>) -> Void
    ) {
        let credentials = NightscoutUploaderCredentials(url: downloaderCredentials.url, apiSecret: apiSecret)
        let testUploader = NightscoutUploader(credentials: credentials)
        testUploader.verifyAuthorization { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(credentials))
            }
        }
    }

    /// Validates a Nightscout site URL and API secret.
    /// - Parameter url: The Nightscout site URL to validate.
    /// - Parameter apiSecret: The API secret to validate.
    /// - Parameter completion: The completion handler for the result of the validation request.
    /// - Parameter result: The result of the validation. In the case of success, this result will contain a valid credentials instance.
    public static func validate(
        url: URL,
        apiSecret: String,
        completion: @escaping (_ result: NightscoutResult<NightscoutUploaderCredentials>) -> Void
    ) {
        NightscoutDownloaderCredentials.validate(url: url) { result in
            switch result {
            case .success(let downloaderCredentials):
                validate(downloaderCredentials: downloaderCredentials, apiSecret: apiSecret, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

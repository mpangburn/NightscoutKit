//
//  NightscoutError.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 3/24/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Foundation


/// Describes an error occurring in communication with a Nightscout site.
public enum NightscoutError: LocalizedError {
    /// An error that occurs when the Nightscout URL is invalid.
    case invalidURL

    /// An error that occurs when attempting to upload, update, or delete Nightscout entities without providing the API secret.
    case missingAPISecret

    /// An error that occurs when fetching Nightscout data.
    /// The associated value contains the error from the call to `URLSession.dataTask`.
    case fetchError(Error)

    /// An error that occurs when uploading Nightscout data.
    /// The associated value contains the error from the call to `URLSession.dataTask` or `URLSession.uploadTask`.
    case uploadError(Error)

    /// An error that occurs when the `URLResponse` received is not an `HTTPURLResponse`.
    case notAnHTTPURLResponse

    /// An error that occurs when the HTTP status code 401 is returned.
    /// If this error results from an attempt to upload, modify, or delete a Nightscout entity, a possible cause is an invalid API secret.
    case unauthorized

    /// An error that occurs when an unexpected HTTP response is returned.
    /// The associated value contains the HTTP status code and the body of the message response.
    case httpError(statusCode: Int, body: String)

    /// An error that occurs when the received data cannot be parsed as JSON.
    /// The associated value contains the error from the call to `JSONSerialization.jsonObject(with:options:)`.
    case jsonParsingError(Error)

    /// An error that occurs when the received data can be parsed as JSON but does not match the expected format of a Nightscout entity.
    /// The associated value contains the data which could not be parsed.
    case dataParsingFailure(Data)
}

extension NightscoutError {
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return NSLocalizedString("Invalid Nightscout URL. Verify that the Nightscout URL is correct.", comment: "The error description and recovery message for an invalid Nightscout URL")
        case .missingAPISecret:
            return NSLocalizedString("Missing API secret. The API secret is required for upload, update, and delete operations.", comment: "The error description for a missing API secret")
        case .fetchError(let error):
            let format = NSLocalizedString("Fetch error: %@", comment: "The error description for a data fetch error")
            return String(format: format, error.localizedDescription)
        case .uploadError(let error):
            let format = NSLocalizedString("Upload error: %@", comment: "The error description for a data upload error")
            return String(format: format, error.localizedDescription)
        case .notAnHTTPURLResponse:
            return NSLocalizedString("The response received was not an HTTP URL response.", comment: "The error description for non-HTTP URL response")
        case .unauthorized:
            return NSLocalizedString("Unauthorized. Verify that the Nightscout URL and API secret are correct.", comment: "The error description and recovery message for an unauthorized attempt to access data")
        case .httpError(statusCode: let statusCode, body: let body):
            let format = NSLocalizedString("HTTP Error %d: %@", comment: "The error description for an HTTP error response")
            return String(format: format, statusCode, body)
        case .jsonParsingError(let error):
            let format = NSLocalizedString("JSON parsing error: %@", comment: "The error description for a JSON parsing error")
            return String(format: format, error.localizedDescription)
        case .dataParsingFailure(let data):
            let format = NSLocalizedString("Data parsing failure. Consider submitting a issue report to https://github.com/mpangburn/NightscoutKit/issues with the following information: %@", comment: "The error description and bug report recommendation for a data parsing failure")
            let body = String(data: data, encoding: .utf8)!
            return String(format: format, body)
        }
    }
}

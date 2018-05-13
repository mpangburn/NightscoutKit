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
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return NSLocalizedString("Invalid Nightscout URL.", comment: "The error description for an invalid Nightscout URL")
        case .missingAPISecret:
            return NSLocalizedString("Missing Nightscout API secret.", comment: "The error description for a missing API secret")
        case .fetchError(let error):
            let format = NSLocalizedString("Fetch error: %@", comment: "The error description for a data fetch error")
            return String(format: format, error.localizedDescription)
        case .uploadError(let error):
            let format = NSLocalizedString("Upload error: %@", comment: "The error description for a data upload error")
            return String(format: format, error.localizedDescription)
        case .notAnHTTPURLResponse:
            return NSLocalizedString("The response received was not an HTTP URL response.", comment: "The error description a for non-HTTP URL response")
        case .unauthorized:
            return NSLocalizedString("Unauthorized.", comment: "The error description for an unauthorized attempt to access data")
        case .httpError(statusCode: let statusCode, body: _):
            return HTTPURLResponse.localizedString(forStatusCode: statusCode)
        case .jsonParsingError(let error):
            let format = NSLocalizedString("JSON parsing error: %@", comment: "The error description for a JSON parsing error")
            return String(format: format, error.localizedDescription)
        case .dataParsingFailure(let data):
            let format = NSLocalizedString("Data parsing failure.", comment: "The error description for a data parsing failure")
            let body = String(data: data, encoding: .utf8)!
            return String(format: format, body)
        }
    }

    public var failureReason: String? {
        switch self {
        case .invalidURL:
            return nil
        case .missingAPISecret:
            return NSLocalizedString("Attempting to upload, update, or delete Nightscout data without providing the API secret will fail.", comment: "The failure reason for a 'missing API secret' error")
        case .fetchError(let error as NSError):
            return error.localizedFailureReason
        case .uploadError(let error as NSError):
            return error.localizedFailureReason
        case .notAnHTTPURLResponse:
            return NSLocalizedString("Attempting to access data from a non-HTTP source will fail.", comment: "The failure reason for a 'non-HTTP URL response' error")
        case .unauthorized:
            return nil
        case .httpError(statusCode: _, body: _):
            return nil
        case .jsonParsingError(let error as NSError):
            return error.localizedFailureReason
        case .dataParsingFailure(_):
            return NSLocalizedString("The data received did not match the expected format.", comment: "The failure reason for a 'data parsing failure' error")
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .invalidURL:
            return NSLocalizedString("Verify that the Nightscout URL is correct.", comment: "The recovery suggestion for an invalid Nightscout URL")
        case .missingAPISecret:
            return NSLocalizedString("Verify that the Nightscout API secret has been entered.", comment: "The recovery suggestion for a missing API secret")
        case .fetchError(let error as NSError):
            return error.localizedRecoverySuggestion
        case .uploadError(let error as NSError):
            return error.localizedRecoverySuggestion
        case .notAnHTTPURLResponse:
            return NSLocalizedString("Verify that the Nightscout URL is a valid HTTP URL.", comment: "The recovery suggestion for a non-HTTP URL response")
        case .unauthorized:
            return NSLocalizedString("Verify that the Nightscout URL and API secret are correct.", comment: "The recovery suggestion for an unauthorized attempt to access data")
        case .httpError(statusCode: _, body: _):
            return nil
        case .jsonParsingError(let error as NSError):
            return error.localizedRecoverySuggestion
        case .dataParsingFailure(let data):
            let format = NSLocalizedString("If you're certain the Nightscout URL and API secret are correct, consider filing an issue at https://github.com/mpangburn/NightscoutKit/issues with the following information:\n%@", comment: "The bug report recommendation for a data parsing failure")
            let body = String(data: data, encoding: .utf8)!
            return String(format: format, body)
        }
    }

    public var helpAnchor: String? {
        switch self {
        case .invalidURL:
            return nil
        case .missingAPISecret:
            return nil
        case .fetchError(let error as NSError):
            return error.helpAnchor
        case .uploadError(let error as NSError):
            return error.helpAnchor
        case .notAnHTTPURLResponse:
            return nil
        case .unauthorized:
            return nil
        case .httpError(statusCode: _, body: _):
            return nil
        case .jsonParsingError(let error as NSError):
            return error.helpAnchor
        case .dataParsingFailure(_):
            return nil
        }
    }
}

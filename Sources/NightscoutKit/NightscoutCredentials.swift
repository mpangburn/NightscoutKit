//
//  NightscoutCredentials.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 9/4/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

/// Describes the validated Nightscout credentials—either download or both upload and download.
public enum NightscoutCredentials: Hashable {
    case downloader(NightscoutDownloaderCredentials)
    case uploader(NightscoutUploaderCredentials)

    /// The validated Nightscout URL.
    public var url: URL {
        switch self {
        case .downloader(let credentials):
            return credentials.url
        case .uploader(let credentials):
            return credentials.url
        }
    }

    /// The validated Nightscout API secret, or `nil` if no upload credentials are present.
    public var apiSecret: String? {
        switch self {
        case .downloader(_):
            return nil
        case .uploader(let credentials):
            return credentials.apiSecret
        }
    }
}

extension NightscoutCredentials: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        do {
            self = .uploader(try container.decode(NightscoutUploaderCredentials.self))
        } catch {
            self = .downloader(try container.decode(NightscoutDownloaderCredentials.self))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .downloader(let credentials):
            try container.encode(credentials)
        case .uploader(let credentials):
            try container.encode(credentials)
        }
    }
}

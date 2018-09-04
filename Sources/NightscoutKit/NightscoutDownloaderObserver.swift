//
//  NightscoutDownloaderObserver.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 6/25/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Oxygen


/// A type that observes the operations of a `NightscoutDownloader` instance.
public protocol NightscoutDownloaderObserver: AnyObject {
    /// Called when an observed `NightscoutDownloader` instance successfully fetches the site status.
    /// - Parameter downloader: The `NightscoutDownloader` instance that performed the operation.
    /// - Parameter status: The status fetched.
    func downloader(_ downloader: NightscoutDownloader, didFetchStatus status: NightscoutStatus)

    /// Called when an observed `NightscoutDownloader` instance successfully fetches entries.
    /// - Parameter downloader: The `NightscoutDownloader` instance that performed the operation.
    /// - Parameter entries: The entries fetched.
    func downloader(_ downloader: NightscoutDownloader, didFetchEntries entries: [NightscoutEntry])

    /// Called when an observed `NightscoutDownloader` instance successfully fetches treatments.
    /// - Parameter downloader: The `NightscoutDownloader` instance that performed the operation.
    /// - Parameter treatments: The treatments fetched.
    func downloader(_ downloader: NightscoutDownloader, didFetchTreatments treatments: [NightscoutTreatment])

    /// Called when an observed `NightscoutDownloader` instance successfully fetches profile records.
    /// - Parameter downloader: The `NightscoutDownloader` instance that performed the operation.
    /// - Parameter records: The profile records fetched.
    func downloader(_ downloader: NightscoutDownloader, didFetchProfileRecords records: [NightscoutProfileRecord])

    /// Called when an observed `NightscoutDownloader` instance successfully fetches device statuses.
    /// - Parameter downloader: The `NightscoutDownloader` instance that performed the operation.
    /// - Parameter deviceStatuses: The device statuses fetched.
    func downloader(_ downloader: NightscoutDownloader, didFetchDeviceStatuses deviceStatuses: [NightscoutDeviceStatus])

    /// Called when an observed `NightscoutDownloader` instance encounters an error when performing an operation.
    /// - Parameter downloader: The `NightscoutDownloader` instance that performed the operation.
    /// - Parameter error: The error encountered.
    func downloader(_ downloader: NightscoutDownloader, didErrorWith error: NightscoutError)
}

// MARK: - Default Implementations

extension NightscoutDownloaderObserver {
    public func downloader(_ downloader: NightscoutDownloader, didFetchStatus status: NightscoutStatus) { }
    public func downloader(_ downloader: NightscoutDownloader, didFetchEntries entries: [NightscoutEntry]) { }
    public func downloader(_ downloader: NightscoutDownloader, didFetchTreatments treatments: [NightscoutTreatment]) { }
    public func downloader(_ downloader: NightscoutDownloader, didFetchProfileRecords records: [NightscoutProfileRecord]) { }
    public func downloader(_ downloader: NightscoutDownloader, didFetchDeviceStatuses deviceStatuses: [NightscoutDeviceStatus]) { }
    public func downloader(_ downloader: NightscoutDownloader, didErrorWith error: NightscoutError) { }
}

// TODO: Unify the below API with `NightscoutUploaderObserver`, likely through the use of protocols.

internal typealias NightscoutDownloaderObserverAction<Payload> = (NightscoutDownloaderObserver, Payload) -> Void

extension NightscoutDownloaderObserver {
    func notify<T>(
        for result: NightscoutResult<T>,
        from downloader: NightscoutDownloader,
        ifSuccess update: NightscoutDownloaderObserverAction<T>,
        ifError errorWork: NightscoutDownloaderObserverAction<NightscoutError>? = nil
    ) {
        result.handle(
            ifSuccess: { update(self, $0) },
            ifFailure: { error in
                errorWork?(self, error)
                self.downloader(downloader, didErrorWith: error)
            }
        )
    }
}

extension RandomAccessCollection where Element == NightscoutDownloaderObserver {
    func concurrentlyNotify<T>(
        for result: NightscoutResult<T>,
        from downloader: NightscoutDownloader,
        ifSuccess update: NightscoutDownloaderObserverAction<T>,
        ifError errorWork: NightscoutDownloaderObserverAction<NightscoutError>? = nil
    ) {
        concurrentForEach { observer in
            observer.notify(for: result, from: downloader, ifSuccess: update, ifError: errorWork)
        }
    }
}

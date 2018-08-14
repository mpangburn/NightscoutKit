//
//  NightscoutObserver.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 7/17/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

/// An observer that responds to interactions with a Nightscout site.
public typealias NightscoutObserver = NightscoutDownloaderObserver & NightscoutUploaderObserver

// MARK: - Override enforcement

/// This class exists only to ensure that observer default protocol implementations
/// are being overriden by its subclasses through compile-time enforcement of the `override` keyword.
open class _NightscoutObserver: NightscoutObserver {
    open func downloader(_ downloader: NightscoutDownloader, didFetchStatus status: NightscoutStatus) { }
    open func downloader(_ downloader: NightscoutDownloader, didFetchEntries entries: [NightscoutEntry]) { }
    open func downloader(_ downloader: NightscoutDownloader, didFetchTreatments treatments: [NightscoutTreatment]) { }
    open func downloader(_ downloader: NightscoutDownloader, didFetchProfileRecords records: [NightscoutProfileRecord]) { }
    open func downloader(_ downloader: NightscoutDownloader, didFetchDeviceStatuses deviceStatuses: [NightscoutDeviceStatus]) { }
    open func downloader(_ downloader: NightscoutDownloader, didErrorWith error: NightscoutError) { }

    open func uploaderDidVerifyAuthorization(_ uploader: NightscoutUploader) { }
    open func uploader(_ uploader: NightscoutUploader, didUploadEntries entries: Set<NightscoutEntry>) { }
    open func uploader(_ uploader: NightscoutUploader, didFailToUploadEntries entries: Set<NightscoutEntry>) { }
    open func uploader(_ uploader: NightscoutUploader, didUploadTreatments treatments: Set<NightscoutTreatment>) { }
    open func uploader(_ uploader: NightscoutUploader, didFailToUploadTreatments treatments: Set<NightscoutTreatment>) { }
    open func uploader(_ uploader: NightscoutUploader, didUpdateTreatments treatments: Set<NightscoutTreatment>) { }
    open func uploader(_ uploader: NightscoutUploader, didFailToUpdateTreatments treatments: Set<NightscoutTreatment>) { }
    open func uploader(_ uploader: NightscoutUploader, didDeleteTreatments treatments: Set<NightscoutTreatment>) { }
    open func uploader(_ uploader: NightscoutUploader, didFailToDeleteTreatments treatments: Set<NightscoutTreatment>) { }
    open func uploader(_ uploader: NightscoutUploader, didUploadProfileRecords records: Set<NightscoutProfileRecord>) { }
    open func uploader(_ uploader: NightscoutUploader, didFailToUploadProfileRecords records: Set<NightscoutProfileRecord>) { }
    open func uploader(_ uploader: NightscoutUploader, didUpdateProfileRecords records: Set<NightscoutProfileRecord>) { }
    open func uploader(_ uploader: NightscoutUploader, didFailToUpdateProfileRecords records: Set<NightscoutProfileRecord>) { }
    open func uploader(_ uploader: NightscoutUploader, didDeleteProfileRecords records: Set<NightscoutProfileRecord>) { }
    open func uploader(_ uploader: NightscoutUploader, didFailToDeleteProfileRecords records: Set<NightscoutProfileRecord>) { }
    open func uploader(_ uploader: NightscoutUploader, didErrorWith error: NightscoutError) { }
}

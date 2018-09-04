//
//  NightscoutDataManager.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 8/14/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Oxygen


/// Manages a `NightscoutDownloader` and optionally a `NightscoutUploader` along with their observers.
open class NightscoutDataManager {
    /// Options for `NightscoutDataManager` configuration.
    public struct Options: OptionSet {
        /// Account for the delay between the success of a POST/PUT/DELETE treatment request and its reflection in a corresponding GET request
        /// when invoking the `mostUpToDateTreatments` method of `NightscoutDataManager`.
        public static let syncTreatmentOperations = Options(rawValue: 1 << 0)

        /// Account for the delay between the success of a POST/PUT/DELETE profile record request and its reflection in a corresponding GET request
        /// when invoking the `mostUpToDateProfileRecords` method of `NightscoutDataManager`.
        public static let syncProfileRecordOperations = Options(rawValue: 1 << 1)

        /// Account for the delay between the success of a POST/PUT/DELETE request and its reflection in a corresponding GET request
        /// when invoking the `mostUpToDate[...]` methods of `NightscoutDataManager`.
        public static let syncOperations: Options = [syncTreatmentOperations, syncProfileRecordOperations]

        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }

    /// The managed data downloader.
    public let downloader: NightscoutDownloader

    /// The managed data uploader.
    /// This property is `nil` if no uploader or credentials are provided upon initialization.
    public let uploader: NightscoutUploader?

    /// The data store observing the operations of the managed downloader and uploader.
    public let dataStore: NightscoutDataStore

    /// The logger recording the operations of the managed downloader and uploader.
    public let logger: NightscoutLogger?

    /// The options used in configuring this instance.
    public let options: Options

    private let treatmentSyncManager: NightscoutTreatmentSyncManager?
    private let profileRecordSyncManager: NightscoutProfileRecordSyncManager?

    /// Creates a new data manager.
    /// - Parameter downloader: The downloader to manage.
    /// - Parameter uploader: The uploader to manage.
    /// - Parameter dataStore: The data store used to observe the operations of the downloader and uploader.
    /// - Parameter logger: The logger used to record the operations of the downloader and uploader. The default value is `nil`.
    /// - Parameter options: The options used in configuring this instance. The default value is `.syncOperations`.
    /// - Returns: A new data manager.
    public init(downloader: NightscoutDownloader, uploader: NightscoutUploader?, dataStore: NightscoutDataStore, logger: NightscoutLogger? = nil, options: Options = .syncOperations) {
        self.downloader = downloader
        self.uploader = uploader
        self.dataStore = dataStore
        self.logger = logger
        self.options = options
        self.treatmentSyncManager = options.contains(.syncTreatmentOperations) ? NightscoutTreatmentSyncManager() : nil
        self.profileRecordSyncManager = options.contains(.syncProfileRecordOperations) ? NightscoutProfileRecordSyncManager() : nil

        let observers = [dataStore, logger, treatmentSyncManager, profileRecordSyncManager].compactMap(identity)
        downloader.addObservers(observers)
        uploader?.addObservers(observers)
    }

    /// Creates a new data manager.
    /// - Parameter downloaderCredentials: The credentials used to initialize a new `NightscoutDownloader` to manage.
    /// - Parameter dataStore: The data store used to observe the operations of the downloader.
    /// - Parameter logger: The logger used to record the operations of the downloader. The default value is `nil`.
    /// - Parameter options: The options used in configuring this instance. The default value is `.syncOperations`.
    /// - Returns: A new data manager.
    public convenience init(downloaderCredentials: NightscoutDownloaderCredentials, dataStore: NightscoutDataStore, logger: NightscoutLogger? = nil, options: Options = .syncOperations) {
        let downloader = NightscoutDownloader(credentials: downloaderCredentials)
        self.init(downloader: downloader, uploader: nil, dataStore: dataStore, logger: logger, options: options)
    }

    /// Creates a new data manager.
    /// - Parameter uploaderCredentials: The credentials used to initialize the new `NightscoutDownloader` and `NightscoutUploader` instances to manage.
    /// - Parameter dataStore: The data store used to observe the operations of the downloader and uploader.
    /// - Parameter logger: The logger used to record the operations of the downloader and uploader. The default value is `nil`.
    /// - Parameter options: The options used in configuring this instance. The default value is `.syncOperations`.
    /// - Returns: A new data manager.
    public convenience init(uploaderCredentials: NightscoutUploaderCredentials, dataStore: NightscoutDataStore, logger: NightscoutLogger? = nil, options: Options = .syncOperations) {
        let downloader = NightscoutDownloader(credentials: uploaderCredentials.withoutUploadPermissions)
        let uploader = NightscoutUploader(credentials: uploaderCredentials)
        self.init(downloader: downloader, uploader: uploader, dataStore: dataStore, logger: logger, options: options)
    }

    /// Returns `true` if this instance manages a `NightscoutUploader`.
    public var isAuthorizedToUpload: Bool {
        return uploader != nil
    }

    /// Returns the most up to date treatments from the data store.
    /// If `options` contains `.syncTreatmentOperations`, recent POST/PUT/DELETE successes from the managed uploader will be applied to resulting array.
    /// - Returns: The most up to date treatments from the data store.
    public func mostUpToDateTreatments() -> [NightscoutTreatment] {
        var treatments = SortedArray(sorted: dataStore.fetchedTreatments, areInIncreasingOrder: their(\.date, >))
        treatmentSyncManager?.applyUpdates(to: &treatments, insertingAllNewerUploads: true)
        return Array(treatments)
    }

    /// Returns the most up to date profile records from the data store.
    /// If `options` contains `.syncProfileRecordOperations`, recent POST/PUT/DELETE successes from the managed uploader will be applied to resulting array.
    /// - Returns: The most up to date profile records from the data store.
    public func mostUpToDateProfileRecords() -> [NightscoutProfileRecord] {
        var profileRecords = SortedArray(sorted: dataStore.fetchedRecords, areInIncreasingOrder: their(\.date, >))
        profileRecordSyncManager?.applyUpdates(to: &profileRecords, insertingAllNewerUploads: true)
        return Array(profileRecords)
    }
}

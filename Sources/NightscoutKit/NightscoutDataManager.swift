//
//  NightscoutDataManager.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 8/14/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Oxygen


/// A type that observes the operations of a `NightscoutDataManager` instance.
public protocol NightscoutDataManagerObserver: AnyObject {
    func nightscoutDataManagerDidUpdateCredentials(_ manager: NightscoutDataManager)
}

/// Manages a `NightscoutDownloader` and optionally a `NightscoutUploader` along with their observers.
open class NightscoutDataManager: NonatomicObservable {
    public typealias Observer = NightscoutDataManagerObserver

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
    public private(set) var downloader: NightscoutDownloader

    /// The managed data uploader.
    /// This property is `nil` if no uploader or credentials are provided upon initialization.
    public private(set) var uploader: NightscoutUploader?

    /// The data store observing the operations of the managed downloader and uploader.
    public let dataStore: NightscoutDataStore

    /// The logger recording the operations of the managed downloader and uploader.
    public let logger: NightscoutLogger?

    /// The options used in configuring this instance.
    public let options: Options

    /// The credentials used to create the managed `NightscoutUploader` and/or `NightscoutDownloader`.
    ///
    /// Setting this property clears cached data.
    public var credentials: NightscoutCredentials {
        get {
            if let uploader = uploader {
                return .uploader(uploader.credentials)
            } else {
                return .downloader(downloader.credentials)
            }
        }
        set {
            switch credentials {
            case .downloader(let credentials):
                downloader.credentials = credentials
                uploader = nil
            case .uploader(let credentials):
                downloader.credentials = credentials.withoutUploadPermissions
                if let uploader = uploader {
                    uploader.credentials = credentials
                } else {
                    uploader = NightscoutUploader(credentials: credentials)
                    uploader?.addObservers(nightscoutObservers)
                }
            }
            dataStore.clearAllDataCache()
            treatmentSyncManager?.clearCache()
            profileRecordSyncManager?.clearCache()
            self.observers.forEach { $0.nightscoutDataManagerDidUpdateCredentials(self) }
        }
    }

    private let treatmentSyncManager: NightscoutTreatmentSyncManager?
    private let profileRecordSyncManager: NightscoutProfileRecordSyncManager?

    private var nightscoutObservers: [NightscoutObserver] {
        return [dataStore, logger, treatmentSyncManager, profileRecordSyncManager].compactMap(identity)
    }

    internal var _observers: [ObjectIdentifier: Weak<NightscoutDataManagerObserver>] = [:]

    /// Creates a new data manager.
    /// - Parameter downloader: The downloader to manage.
    /// - Parameter uploader: The uploader to manage.
    /// - Parameter dataStore: The data store used to observe the operations of the downloader and uploader.
    /// - Parameter logger: The logger used to record the operations of the downloader and uploader. The default value is `nil`.
    /// - Parameter options: The options used in configuring this instance. The default value is `.syncOperations`.
    /// - Returns: A new data manager.
    internal init(downloader: NightscoutDownloader, uploader: NightscoutUploader?, dataStore: NightscoutDataStore, logger: NightscoutLogger? = nil, options: Options = .syncOperations) {
        self.downloader = downloader
        self.uploader = uploader
        self.dataStore = dataStore
        self.logger = logger
        self.options = options
        self.treatmentSyncManager = options.contains(.syncTreatmentOperations) ? NightscoutTreatmentSyncManager() : nil
        self.profileRecordSyncManager = options.contains(.syncProfileRecordOperations) ? NightscoutProfileRecordSyncManager() : nil

        let nightscoutObservers = self.nightscoutObservers
        downloader.addObservers(nightscoutObservers)
        uploader?.addObservers(nightscoutObservers)
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

    /// Creates a new data manager.
    /// - Parameter credentials: The credentials used to initialize the new `NightscoutUploader` and/or `NightscoutDownloader` instances to manage.
    /// - Parameter dataStore: The data store used to observe the operations of the downloader and uploader.
    /// - Parameter logger: The logger used to record the operations of the downloader and uploader. The default value is `nil`.
    /// - Parameter options: The options used in configuring this instance. The default value is `.syncOperations`.
    /// - Returns: A new data manager.
    public convenience init(credentials: NightscoutCredentials, dataStore: NightscoutDataStore, logger: NightscoutLogger? = nil, options: Options = .syncOperations) {
        switch credentials {
        case .downloader(let credentials):
            self.init(downloaderCredentials: credentials, dataStore: dataStore, logger: logger, options: options)
        case .uploader(let credentials):
            self.init(uploaderCredentials: credentials, dataStore: dataStore, logger: logger, options: options)
        }
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

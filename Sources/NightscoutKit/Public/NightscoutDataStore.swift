//
//  NightscoutDataStore.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 3/23/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

/// A highly configurable class that stores data produced or received
/// by the operations of an observed `Nightscout` instance.
open class NightscoutDataStore: _NightscoutObserver {
    /// Describes the set of possible options for a `NightscoutDataStore` instance.
    public struct Options: OptionSet {
        /// Cache received data.
        ///
        /// If this option is set, `NightscoutDataStore` properties will cache received data,
        /// storing the most recently received data at the front of the array.
        /// If this option is not set, `NightscoutDataStore` properties will be replaced as
        /// the observed `Nightscout` instance performs operations.
        public static let cacheReceivedData = Options(rawValue: 1 << 0)

        /// Store the entries fetched by the observed `Nightscout` instance.
        public static let storeFetchedEntries = Options(rawValue: 1 << 1)

        /// Store the entries uploaded by the observed `Nightscout` instance.
        public static let storeUploadedEntries = Options(rawValue: 1 << 2)

        /// Store the entries that the observed `Nightscout` instance failed to upload.
        public static let storeFailedUploadEntries = Options(rawValue: 1 << 3)

        /// Store the treatments fetched by the observed `Nightscout` instance.
        public static let storeFetchedTreatments = Options(rawValue: 1 << 4)

        /// Store the treatments uploaded by the observed `Nightscout` instance.
        public static let storeUploadedTreatments = Options(rawValue: 1 << 5)

        /// Store the treatments that the observed `Nightscout` instance failed to upload.
        public static let storeFailedUploadTreatments = Options(rawValue: 1 << 6)

        /// Store the treatments updated by the observed `Nightscout` instance.
        public static let storeUpdatedTreatments = Options(rawValue: 1 << 7)

        /// Store the treatments that the observed `Nightscout` instance failed to update.
        public static let storeFailedUpdateTreatments = Options(rawValue: 1 << 8)

        /// Store the treatments deleted by the observed `Nightscout` instance.
        public static let storeDeletedTreatments = Options(rawValue: 1 << 9)

        /// Store the treatments that the observed `Nightscout` instance failed to delete.
        public static let storeFailedDeleteTreatments = Options(rawValue: 1 << 10)

        /// Store the profile records fetched by the observed `Nightscout` instance.
        public static let storeFetchedRecords = Options(rawValue: 1 << 11)

        /// Store the profile records uploaded by the observed `Nightscout` instance.
        public static let storeUploadedRecords = Options(rawValue: 1 << 12)

        /// Store the profile records that the observed `Nightscout` instance failed to upload.
        public static let storeFailedUploadRecords = Options(rawValue: 1 << 13)

        /// Store the profile records updated by the observed `Nightscout` instance.
        public static let storeUpdatedRecords = Options(rawValue: 1 << 14)

        /// Store the profile records that the observed `Nightscout` instance failed to update.
        public static let storeFailedUpdateRecords = Options(rawValue: 1 << 15)

        /// Store the profile records deleted by the observed `Nightscout` instance.
        public static let storeDeletedRecords = Options(rawValue: 1 << 16)

        /// Store the profile records that the observed `Nightscout` instance failed to delete.
        public static let storeFailedDeleteRecords = Options(rawValue: 1 << 17)

        /// Store the device statuses fetched by the observed `Nightscout` instance.
        public static let storeFetchedDeviceStatuses = Options(rawValue: 1 << 18)

        /// Store fetched entries, uploaded entries, and entries that failed to upload.
        public static let storeAllEntryData: Options = [.storeFetchedEntries, .storeUploadedEntries, .storeFailedUploadEntries]

        /// Store fetched treatments, uploaded treatments, treatments that failed to upload,
        /// updated treatments, treatments that failed to update, deleted treatments, and treatments that failed to delete.
        public static let storeAllTreatmentData: Options = [
            .storeFetchedTreatments, .storeUploadedTreatments, .storeFailedUploadTreatments, .storeUpdatedTreatments,
            .storeFailedUpdateTreatments, .storeDeletedTreatments, .storeFailedDeleteTreatments
        ]

        /// Store fetched records, uploaded records, records that failed to upload,
        /// updated records, records that failed to update, deleted records, and records that failed to delete.
        static let storeAllRecordData: Options = [
            .storeFetchedRecords, .storeUploadedRecords, .storeFailedUploadRecords, .storeUpdatedRecords,
            .storeFailedUpdateRecords, .storeDeletedRecords, .storeFailedDeleteRecords
        ]

        /// Store fetched device statuses.
        static let storeAllDeviceStatusData: Options = [.storeFetchedDeviceStatuses]

        /// Store fetched entries, treatments, records, and device statuses.
        public static let storeAllFetchedData: Options = [.storeFetchedEntries, .storeFetchedTreatments, .storeFetchedRecords, .storeFetchedDeviceStatuses]

        /// Store uploaded entries, treatments, and records.
        public static let storeAllUploadedData: Options = [.storeUploadedEntries, .storeUploadedTreatments, .storeUploadedRecords]

        /// Store entries, treatments, and records that failed to upload.
        public static let storeAllFailedUploadData: Options = [.storeFailedUploadEntries, .storeFailedUploadTreatments, .storeFailedUploadRecords]

        /// Store updated treatments and records.
        public static let storeAllUpdatedData: Options = [.storeUpdatedTreatments, .storeUpdatedRecords]

        /// Store treatments and records that failed to update.
        public static let storeAllFailedUpdateData: Options = [.storeFailedUpdateTreatments, .storeFailedUpdateRecords]

        /// Store deleted treatments and records.
        public static let storeAllDeletedData: Options = [.storeDeletedTreatments, .storeDeletedRecords]

        /// Store treatments and records that failed to delete.
        public static let storeAllFailedDeleteData: Options = [.storeFailedDeleteTreatments, .storeFailedDeleteRecords]

        /// Store all failed uploads, updates, and deletions.
        public static let storeAllFailureData: Options = [.storeAllFailedUploadData, .storeAllFailedUpdateData, .storeAllFailedDeleteData]

        /// Store the data produced by all operations.
        public static let storeAllData: Options = [.storeAllFetchedData, .storeAllUploadedData, .storeAllDeletedData, .storeAllFailureData]

        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }

    // MARK: - Private properties

    private let _options: ThreadSafe<Options>

    private let _nightscoutHasAuthorization: ThreadSafe<Bool?> = ThreadSafe(nil)

    private let _fetchedStatus: ThreadSafe<NightscoutStatus?> = ThreadSafe(nil)

    private let _fetchedEntries: ThreadSafe<[NightscoutEntry]> = ThreadSafe([])
    private let _uploadedEntries: ThreadSafe<[NightscoutEntry]> = ThreadSafe([])
    private let _failedUploadEntries: ThreadSafe<[NightscoutEntry]> = ThreadSafe([])

    private let _fetchedTreatments: ThreadSafe<[NightscoutTreatment]> = ThreadSafe([])
    private let _uploadedTreatments: ThreadSafe<[NightscoutTreatment]> = ThreadSafe([])
    private let _failedUploadTreatments: ThreadSafe<[NightscoutTreatment]> = ThreadSafe([])
    private let _updatedTreatments: ThreadSafe<[NightscoutTreatment]> = ThreadSafe([])
    private let _failedUpdateTreatments: ThreadSafe<[NightscoutTreatment]> = ThreadSafe([])
    private let _deletedTreatments: ThreadSafe<[NightscoutTreatment]> = ThreadSafe([])
    private let _failedDeleteTreatments: ThreadSafe<[NightscoutTreatment]> = ThreadSafe([])

    private let _fetchedRecords: ThreadSafe<[NightscoutProfileRecord]> = ThreadSafe([])
    private let _uploadedRecords: ThreadSafe<[NightscoutProfileRecord]> = ThreadSafe([])
    private let _failedUploadRecords: ThreadSafe<[NightscoutProfileRecord]> = ThreadSafe([])
    private let _updatedRecords: ThreadSafe<[NightscoutProfileRecord]> = ThreadSafe([])
    private let _failedUpdateRecords: ThreadSafe<[NightscoutProfileRecord]> = ThreadSafe([])
    private let _deletedRecords: ThreadSafe<[NightscoutProfileRecord]> = ThreadSafe([])
    private let _failedDeleteRecords: ThreadSafe<[NightscoutProfileRecord]> = ThreadSafe([])

    private let _fetchedDeviceStatuses: ThreadSafe<[NightscoutDeviceStatus]> = ThreadSafe([])

    private let _lastError: ThreadSafe<NightscoutError?> = ThreadSafe(nil)

    // MARK: - Public properties

    /// The options to use in storing Nightscout data.
    ///
    /// This value is immutable. Specify options when creating the data store using `.init(options:)`.
    public var options: Options { return _options.value }

    /// A boolean value representing whether the observed `Nightscout` instance has authorization.
    ///
    /// This value is set to `true` when `Nightscout.verifyAuthorization()` succeeds
    /// and `false` when the `Nightscout` instance produces an `.invalidURL`, `.missingAPISecret`, or `.unauthorized` error.
    public var nightscoutHasAuthorization: Bool? { return _nightscoutHasAuthorization.value }

    /// The most recently fetched site status.
    public var fetchedStatus: NightscoutStatus? { return _fetchedStatus.value }

    /// The most recently fetched entries.
    ///
    /// If `options` does not contain `.storeFetchedEntries`, this property will not be updated.
    ///
    /// If `options` contains `.cacheReceivedData`, this property will accumulate entries as they are fetched,
    /// with the most recently fetched entries at the front of the array.
    /// If not, this property be replaced each time the observed `Nightscout` instance fetches entries.
    public var fetchedEntries: [NightscoutEntry] { return _fetchedEntries.value }

    /// The most recently uploaded entries.
    ///
    /// If `options` does not contain `.storeUploadedEntries`, this property will not be updated.
    ///
    /// If `options` contains `.cacheReceivedData`, this property will accumulate entries as they are uploaded,
    /// with the most recently uploaded entries at the front of the array.
    /// If not, this property be replaced each time the observed `Nightscout` instance uploads entries.
    public var uploadedEntries: [NightscoutEntry] { return _uploadedEntries.value }

    /// The most entries that failed to upload.
    ///
    /// If `options` does not contain `.storeFailedUploadEntries`, this property will not be updated.
    ///
    /// If `options` contains `.cacheReceivedData`, this property will accumulate entries as they fail to upload,
    /// with the most recent failures at the front of the array.
    /// If not, this property be replaced each time the observed `Nightscout` instance fails to upload entries.
    public var failedUploadEntries: [NightscoutEntry] { return _failedUploadEntries.value }

    /// The most recently fetched treatments.
    ///
    /// If `options` does not contain `.storeFetchedTreatments`, this property will not be updated.
    ///
    /// If `options` contains `.cacheReceivedData`, this property will accumulate treatments as they are fetched,
    /// with the most recently fetched treatments at the front of the array.
    /// If not, this property be replaced each time the observed `Nightscout` instance fetches treatments.
    public var fetchedTreatments: [NightscoutTreatment] { return _fetchedTreatments.value }

    /// The most recently uploaded treatments.
    ///
    /// If `options` does not contain `.storeUploadedTreatments`, this property will not be updated.
    ///
    /// If `options` contains `.cacheReceivedData`, this property will accumulate treatments as they are uploaded,
    /// with the most recently uploaded treatments at the front of the array.
    /// If not, this property be replaced each time the observed `Nightscout` instance uploads treatments.
    public var uploadedTreatments: [NightscoutTreatment] { return _uploadedTreatments.value }

    /// The most treatments that failed to upload.
    ///
    /// If `options` does not contain `.storeFailedUploadTreatments`, this property will not be updated.
    ///
    /// If `options` contains `.cacheReceivedData`, this property will accumulate treatments as they fail to upload,
    /// with the most recent failures at the front of the array.
    /// If not, this property be replaced each time the observed `Nightscout` instance fails to upload treatments.
    public var failedUploadTreatments: [NightscoutTreatment] { return _failedUploadTreatments.value }

    /// The most recently updated treatments.
    ///
    /// If `options` does not contain `.storeUpdatedTreatments`, this property will not be updated.
    ///
    /// If `options` contains `.cacheReceivedData`, this property will accumulate treatments as they are updated,
    /// with the most recently updated treatments at the front of the array.
    /// If not, this property be replaced each time the observed `Nightscout` instance updates treatments.
    public var updatedTreatments: [NightscoutTreatment] { return _updatedTreatments.value }

    /// The most treatments that failed to update.
    ///
    /// If `options` does not contain `.storeFailedUpdateTreatments`, this property will not be updated.
    ///
    /// If `options` contains `.cacheReceivedData`, this property will accumulate treatments as they fail to update,
    /// with the most recent failures at the front of the array.
    /// If not, this property be replaced each time the observed `Nightscout` instance fails to update treatments.
    public var failedUpdateTreatments: [NightscoutTreatment] { return _failedUpdateTreatments.value }

    /// The most recently deleted treatments.
    ///
    /// If `options` does not contain `.storeDeletedTreatments`, this property will not be updated.
    ///
    /// If `options` contains `.cacheReceivedData`, this property will accumulate treatments as they are deleted,
    /// with the most recently deleted treatments at the front of the array.
    /// If not, this property be replaced each time the observed `Nightscout` instance deletes treatments.
    public var deletedTreatments: [NightscoutTreatment] { return _deletedTreatments.value }

    /// The most treatments that failed to delete.
    ///
    /// If `options` does not contain `.storeFailedDeleteTreatments`, this property will not be updated.
    ///
    /// If `options` contains `.cacheReceivedData`, this property will accumulate treatments as they fail to delete,
    /// with the most recent failures at the front of the array.
    /// If not, this property be replaced each time the observed `Nightscout` instance fails to delete treatments.
    public var failedDeleteTreatments: [NightscoutTreatment] { return _failedDeleteTreatments.value }

    /// The most recently fetched profile records.
    ///
    /// If `options` does not contain `.storeFetchedRecords`, this property will not be updated.
    ///
    /// If `options` contains `.cacheReceivedData`, this property will accumulate records as they are fetched,
    /// with the most recently fetched records at the front of the array.
    /// If not, this property be replaced each time the observed `Nightscout` instance fetches records.
    public var fetchedRecords: [NightscoutProfileRecord] { return _fetchedRecords.value }

    /// The most recently uploaded profile records.
    ///
    /// If `options` does not contain `.storeUploadedRecords`, this property will not be updated.
    ///
    /// If `options` contains `.cacheReceivedData`, this property will accumulate records as they are uploaded,
    /// with the most recently uploaded records at the front of the array.
    /// If not, this property be replaced each time the observed `Nightscout` instance uploads records.
    public var uploadedRecords: [NightscoutProfileRecord] { return _uploadedRecords.value }

    /// The most profile records that failed to upload.
    ///
    /// If `options` does not contain `.storeFailedUploadRecords`, this property will not be updated.
    ///
    /// If `options` contains `.cacheReceivedData`, this property will accumulate records as they fail to upload,
    /// with the most recent failures at the front of the array.
    /// If not, this property be replaced each time the observed `Nightscout` instance fails to upload records.
    public var failedUploadRecords: [NightscoutProfileRecord] { return _failedUploadRecords.value }

    /// The most recently updated profile records.
    ///
    /// If `options` does not contain `.storeUpdatedRecords`, this property will not be updated.
    ///
    /// If `options` contains `.cacheReceivedData`, this property will accumulate records as they are updated,
    /// with the most recently updated records at the front of the array.
    /// If not, this property be replaced each time the observed `Nightscout` instance updates records.
    public var updatedRecords: [NightscoutProfileRecord] { return _updatedRecords.value }

    /// The most profile records that failed to update.
    ///
    /// If `options` does not contain `.storeFailedUpdateRecords`, this property will not be updated.
    ///
    /// If `options` contains `.cacheReceivedData`, this property will accumulate records as they fail to update,
    /// with the most recent failures at the front of the array.
    /// If not, this property be replaced each time the observed `Nightscout` instance fails to update records.
    public var failedUpdateRecords: [NightscoutProfileRecord] { return _failedUpdateRecords.value }

    /// The most recently deleted profile records.
    ///
    /// If `options` does not contain `.storeDeletedRecords`, this property will not be updated.
    ///
    /// If `options` contains `.cacheReceivedData`, this property will accumulate records as they are deleted,
    /// with the most recently deleted records at the front of the array.
    /// If not, this property be replaced each time the observed `Nightscout` instance deletes records.
    public var deletedRecords: [NightscoutProfileRecord] { return _deletedRecords.value }

    /// The most profile records that failed to delete.
    ///
    /// If `options` does not contain `.storeFailedDeleteRecords`, this property will not be updated.
    ///
    /// If `options` contains `.cacheReceivedData`, this property will accumulate records as they fail to delete,
    /// with the most recent failures at the front of the array.
    /// If not, this property be replaced each time the observed `Nightscout` instance fails to delete records.
    public var failedDeleteRecords: [NightscoutProfileRecord] { return _failedDeleteRecords.value }

    /// The most recently fetched device statuses.
    ///
    /// If `options` does not contain `.storeFetchedDeviceStatuses`, this property will not be updated.
    ///
    /// If `options` contains `.cacheReceivedData`, this property will accumulate device statuses as they are fetched,
    /// with the most recently fetched device statuses at the front of the array.
    /// If not, this property be replaced each time the observed `Nightscout` instance fetches device statuses.
    public var fetchedDeviceStatuses: [NightscoutDeviceStatus] { return _fetchedDeviceStatuses.value }

    /// The `NightscoutError` most recently encountered by the observed `Nightscout` instance.
    public var lastError: NightscoutError? { return _lastError.value }

    // MARK: - Initializers

    /// Creates a new data store with the specified options.
    /// - Parameter options: The options for data storage.
    public init(options: Options) {
        self._options = ThreadSafe(options)
    }

    /// Creates a new data store that stores only the fetched site status,
    /// verification status of authorization, and last error encountered.
    public convenience override init() {
        self.init(options: [])
    }

    private convenience init(options: Options, cachingReceivedData: Bool) {
        var options = options
        if cachingReceivedData { options.insert(.cacheReceivedData) }
        self.init(options: options)
    }

    /// Creates a new data store that stores the fetched site status,
    /// verification status of authorization, and last error encountered.
    public static func statusStore() -> Self {
        return .init(options: [])
    }

    /// Creates a new data store that stores all entry data.
    /// - Parameter cachingReceivedData: A boolean value determining whether the data store should cache received data.
    ///                                  If this value is `false`, previously received data will be replaced by new incoming data.
    ///                                  Defaults to `true`.
    public static func entryStore(cachingReceivedData: Bool = true) -> Self {
        return .init(options: .storeAllEntryData, cachingReceivedData: cachingReceivedData)
    }

    /// Creates a new data store that stores all treatment data.
    /// - Parameter cachingReceivedData: A boolean value determining whether the data store should cache received data.
    ///                                  If this value is `false`, previously received data will be replaced by new incoming data.
    ///                                  Defaults to `true`.
    public static func treatmentStore(cachingReceivedData: Bool = true) -> Self {
        return .init(options: .storeAllTreatmentData, cachingReceivedData: cachingReceivedData)
    }

    /// Creates a new data store that stores all profile record data.
    /// - Parameter cachingReceivedData: A boolean value determining whether the data store should cache received data.
    ///                                  If this value is `false`, previously received data will be replaced by new incoming data.
    ///                                  Defaults to `true`.
    public static func recordStore(cachingReceivedData: Bool = true) -> Self {
        return .init(options: .storeAllRecordData, cachingReceivedData: cachingReceivedData)
    }

    /// Creates a new data store that stores all device status data.
    /// - Parameter cachingReceivedData: A boolean value determining whether the data store should cache received data.
    ///                                  If this value is `false`, previously received data will be replaced by new incoming data.
    ///                                  Defaults to `true`.
    public static func deviceStatusStore(cachingReceivedData: Bool = true) -> Self {
        return .init(options: .storeAllDeviceStatusData, cachingReceivedData: cachingReceivedData)
    }

    /// Creates a new data store that stores all fetched data.
    /// - Parameter cachingReceivedData: A boolean value determining whether the data store should cache received data.
    ///                                  If this value is `false`, previously received data will be replaced by new incoming data.
    ///                                  Defaults to `true`.
    public static func fetchStore(cachingReceivedData: Bool = true) -> Self {
        return .init(options: .storeAllFetchedData, cachingReceivedData: cachingReceivedData)
    }

    /// Creates a new data store that stores all uploaded data.
    /// - Parameter cachingReceivedData: A boolean value determining whether the data store should cache received data.
    ///                                  If this value is `false`, previously received data will be replaced by new incoming data.
    ///                                  Defaults to `true`.
    public static func uploadStore(cachingReceivedData: Bool = true) -> Self {
        return .init(options: .storeAllUploadedData, cachingReceivedData: cachingReceivedData)
    }

    /// Creates a new data store that stores all data that failed to upload.
    /// - Parameter cachingReceivedData: A boolean value determining whether the data store should cache received data.
    ///                                  If this value is `false`, previously received data will be replaced by new incoming data.
    ///                                  Defaults to `true`.
    public static func failedUploadStore(cachingReceivedData: Bool = true) -> Self {
        return .init(options: .storeAllFailedUploadData, cachingReceivedData: cachingReceivedData)
    }

    /// Creates a new data store that stores all updated data.
    /// - Parameter cachingReceivedData: A boolean value determining whether the data store should cache received data.
    ///                                  If this value is `false`, previously received data will be replaced by new incoming data.
    ///                                  Defaults to `true`.
    public static func updateStore(cachingReceivedData: Bool = true) -> Self {
        return .init(options: .storeAllUpdatedData, cachingReceivedData: cachingReceivedData)
    }

    /// Creates a new data store that stores all data that failed to update.
    /// - Parameter cachingReceivedData: A boolean value determining whether the data store should cache received data.
    ///                                  If this value is `false`, previously received data will be replaced by new incoming data.
    ///                                  Defaults to `true`.
    public static func failedUpdateStore(cachingReceivedData: Bool = true) -> Self {
        return .init(options: .storeAllFailedUpdateData, cachingReceivedData: cachingReceivedData)
    }

    /// Creates a new data store that stores all deleted data.
    /// - Parameter cachingReceivedData: A boolean value determining whether the data store should cache received data.
    ///                                  If this value is `false`, previously received data will be replaced by new incoming data.
    ///                                  Defaults to `true`.
    public static func deleteStore(cachingReceivedData: Bool = true) -> Self {
        return .init(options: .storeAllDeletedData, cachingReceivedData: cachingReceivedData)
    }

    /// Creates a new data store that stores all data that failed to delete.
    /// - Parameter cachingReceivedData: A boolean value determining whether the data store should cache received data.
    ///                                  If this value is `false`, previously received data will be replaced by new incoming data.
    ///                                  Defaults to `true`.
    public static func failedDeleteStore(cachingReceivedData: Bool = true) -> Self {
        return .init(options: .storeAllFailedDeleteData, cachingReceivedData: cachingReceivedData)
    }

    /// Creates a new data store that stores data produced by failed operations.
    /// - Parameter cachingReceivedData: A boolean value determining whether the data store should cache received data.
    ///                                  If this value is `false`, previously received data will be replaced by new incoming data.
    ///                                  Defaults to `true`.
    public static func failureStore(cachingReceivedData: Bool = true) -> Self {
        return .init(options: .storeAllFailureData, cachingReceivedData: cachingReceivedData)
    }

    /// Creates a new data store that stores all data.
    /// - Parameter cachingReceivedData: A boolean value determining whether the data store should cache received data.
    ///                                  If this value is `false`, previously received data will be replaced by new incoming data.
    ///                                  Defaults to `true`.
    public static func allDataStore(cachingReceivedData: Bool = true) -> Self {
        return .init(options: .storeAllData, cachingReceivedData: cachingReceivedData)
    }

    // MARK: - NightscoutObserver

    open override func nightscoutDidVerifyAuthorization(_ nightscout: Nightscout) {
        _nightscoutHasAuthorization.atomicallyAssign(to: true)
    }

    open override func nightscout(_ nightscout: Nightscout, didFetchStatus status: NightscoutStatus) {
        _fetchedStatus.atomicallyAssign(to: status)
    }

    open override func nightscout(_ nightscout: Nightscout, didFetchEntries entries: [NightscoutEntry]) {
        guard options.contains(.storeFetchedEntries) else { return }
        prependOrReplace(entries, keyPath: \._fetchedEntries)
    }

    open override func nightscout(_ nightscout: Nightscout, didUploadEntries entries: Set<NightscoutEntry>) {
        guard options.contains(.storeUploadedEntries) else { return }
        prependOrReplace(entries, keyPath: \._uploadedEntries)
    }

    open override func nightscout(_ nightscout: Nightscout, didFailToUploadEntries entries: Set<NightscoutEntry>) {
        guard options.contains(.storeFailedUploadEntries) else { return }
        prependOrReplace(entries, keyPath: \._failedUploadEntries)
    }

    open override func nightscout(_ nightscout: Nightscout, didFetchTreatments treatments: [NightscoutTreatment]) {
        guard options.contains(.storeFetchedTreatments) else { return }
        prependOrReplace(treatments, keyPath: \._fetchedTreatments)
    }

    open override func nightscout(_ nightscout: Nightscout, didUploadTreatments treatments: Set<NightscoutTreatment>) {
        guard options.contains(.storeUploadedTreatments) else { return }
        prependOrReplace(treatments, keyPath: \._uploadedTreatments)
    }

    open override func nightscout(_ nightscout: Nightscout, didFailToUploadTreatments treatments: Set<NightscoutTreatment>) {
        guard options.contains(.storeFailedUploadTreatments) else { return }
        prependOrReplace(treatments, keyPath: \._failedUploadTreatments)
    }

    open override func nightscout(_ nightscout: Nightscout, didUpdateTreatments treatments: Set<NightscoutTreatment>) {
        guard options.contains(.storeUpdatedTreatments) else { return }
        prependOrReplace(treatments, keyPath: \._updatedTreatments)
    }

    open override func nightscout(_ nightscout: Nightscout, didFailToUpdateTreatments treatments: Set<NightscoutTreatment>) {
        guard options.contains(.storeFailedUpdateTreatments) else { return }
        prependOrReplace(treatments, keyPath: \._failedUpdateTreatments)
    }

    open override func nightscout(_ nightscout: Nightscout, didDeleteTreatments treatments: Set<NightscoutTreatment>) {
        guard options.contains(.storeDeletedTreatments) else { return }
        prependOrReplace(treatments, keyPath: \._deletedTreatments)
    }

    open override func nightscout(_ nightscout: Nightscout, didFailToDeleteTreatments treatments: Set<NightscoutTreatment>) {
        guard options.contains(.storeFailedDeleteTreatments) else { return }
        prependOrReplace(treatments, keyPath: \._failedDeleteTreatments)
    }

    open override func nightscout(_ nightscout: Nightscout, didFetchProfileRecords records: [NightscoutProfileRecord]) {
        guard options.contains(.storeFetchedRecords) else { return }
        prependOrReplace(records, keyPath: \._fetchedRecords)
    }

    open override func nightscout(_ nightscout: Nightscout, didUploadProfileRecords records: Set<NightscoutProfileRecord>) {
        guard options.contains(.storeUploadedRecords) else { return }
        prependOrReplace(records, keyPath: \._uploadedRecords)
    }

    open override func nightscout(_ nightscout: Nightscout, didFailToUploadProfileRecords records: Set<NightscoutProfileRecord>) {
        guard options.contains(.storeFailedUploadRecords) else { return }
        prependOrReplace(records, keyPath: \._failedUploadRecords)
    }

    open override func nightscout(_ nightscout: Nightscout, didUpdateProfileRecords records: Set<NightscoutProfileRecord>) {
        guard options.contains(.storeUpdatedRecords) else { return }
        prependOrReplace(records, keyPath: \._updatedRecords)
    }

    open override func nightscout(_ nightscout: Nightscout, didFailToUpdateProfileRecords records: Set<NightscoutProfileRecord>) {
        guard options.contains(.storeFailedUpdateRecords) else { return }
        prependOrReplace(records, keyPath: \._failedUpdateRecords)
    }

    open override func nightscout(_ nightscout: Nightscout, didDeleteProfileRecords records: Set<NightscoutProfileRecord>) {
        guard options.contains(.storeDeletedRecords) else { return }
        prependOrReplace(records, keyPath: \._deletedRecords)
    }

    open override func nightscout(_ nightscout: Nightscout, didFailToDeleteProfileRecords records: Set<NightscoutProfileRecord>) {
        guard options.contains(.storeFailedDeleteRecords) else { return }
        prependOrReplace(records, keyPath: \._failedDeleteRecords)
    }

    open override func nightscout(_ nightscout: Nightscout, didFetchDeviceStatuses deviceStatuses: [NightscoutDeviceStatus]) {
        guard options.contains(.storeFetchedDeviceStatuses) else { return }
        prependOrReplace(deviceStatuses, keyPath: \._fetchedDeviceStatuses)
    }

    open override func nightscout(_ nightscout: Nightscout, didErrorWith error: NightscoutError) {
        switch error {
        case .invalidURL, .missingAPISecret, .unauthorized:
            _nightscoutHasAuthorization.atomicallyAssign(to: false)
        default:
            break
        }
        _lastError.atomicallyAssign(to: error)
    }

    private func prependOrReplace<S: Sequence>(_ newValues: S, keyPath: KeyPath<NightscoutDataStore, ThreadSafe<[S.Element]>>) {
        let newValues = Array(newValues)
        if options.contains(.cacheReceivedData) {
            self[keyPath: keyPath].atomically { (oldValues: inout [S.Element]) in
                oldValues.insert(contentsOf: newValues, at: 0)
            }
        } else {
            self[keyPath: keyPath].atomicallyAssign(to: newValues)
        }
    }
}

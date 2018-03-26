//
//  NightscoutObserver.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 3/23/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

/// A type that observes the operations of a `Nightscout` instance.
public protocol NightscoutObserver: AnyObject {
    /// Called when an observed `Nightscout` instance successfully verifies authorization.
    /// - Parameter nightscout: The `Nightscout` instance that performed the operation.
    func nightscoutDidVerifyAuthorization(_ nightscout: Nightscout)

    /// Called when an observed `Nightscout` instance successfully fetches the site status.
    /// - Parameter nightscout: The `Nightscout` instance that performed the operation.
    /// - Parameter status: The status fetched.
    func nightscout(_ nightscout: Nightscout, didFetchStatus status: NightscoutStatus)

    /// Called when an observed `Nightscout` instance successfully fetches entries.
    /// - Parameter nightscout: The `Nightscout` instance that performed the operation.
    /// - Parameter entries: The entries fetched.
    func nightscout(_ nightscout: Nightscout, didFetchEntries entries: [NightscoutEntry])

    /// Called when an observed `Nightscout` instance successfully uploads entries.
    /// - Parameter nightscout: The `Nightscout` instance that performed the operation.
    /// - Parameter entries: The entries uploaded.
    func nightscout(_ nightscout: Nightscout, didUploadEntries entries: Set<NightscoutEntry>)

    /// Called when an observed `Nightscout` instance fails to upload entries.
    /// - Parameter nightscout: The `Nightscout` instance that performed the operation.
    /// - Parameter entries: The entries that failed to upload.
    func nightscout(_ nightscout: Nightscout, didFailToUploadEntries entries: Set<NightscoutEntry>)

    /// Called when an observed `Nightscout` instance successfully fetches treatments.
    /// - Parameter nightscout: The `Nightscout` instance that performed the operation.
    /// - Parameter treatments: The treatments fetched.
    func nightscout(_ nightscout: Nightscout, didFetchTreatments treatments: [NightscoutTreatment])

    /// Called when an observed `Nightscout` instance successfully uploads treatments.
    /// - Parameter nightscout: The `Nightscout` instance that performed the operation.
    /// - Parameter treatments: The treatments uploaded.
    func nightscout(_ nightscout: Nightscout, didUploadTreatments treatments: Set<NightscoutTreatment>)

    /// Called when an observed `Nightscout` instance fails to upload treatments.
    /// - Parameter nightscout: The `Nightscout` instance that performed the operation.
    /// - Parameter treatments: The treatments that failed to upload.
    func nightscout(_ nightscout: Nightscout, didFailToUploadTreatments treatments: Set<NightscoutTreatment>)

    /// Called when an observed `Nightscout` instance successfully updates treatments.
    /// - Parameter nightscout: The `Nightscout` instance that performed the operation.
    /// - Parameter treatments: The treatments updated.
    func nightscout(_ nightscout: Nightscout, didUpdateTreatments treatments: Set<NightscoutTreatment>)

    /// Called when an observed `Nightscout` instance fails to update treatments.
    /// - Parameter nightscout: The `Nightscout` instance that performed the operation.
    /// - Parameter treatments: The treatments that failed to update.
    func nightscout(_ nightscout: Nightscout, didFailToUpdateTreatments treatments: Set<NightscoutTreatment>)

    /// Called when an observed `Nightscout` instance successfully deletes treatments.
    /// - Parameter nightscout: The `Nightscout` instance that performed the operation.
    /// - Parameter treatments: The treatments deleted.
    func nightscout(_ nightscout: Nightscout, didDeleteTreatments treatments: Set<NightscoutTreatment>)

    /// Called when an observed `Nightscout` instance fails to delete treatments.
    /// - Parameter nightscout: The `Nightscout` instance that performed the operation.
    /// - Parameter treatments: The treatments that failed to delete.
    func nightscout(_ nightscout: Nightscout, didFailToDeleteTreatments treatments: Set<NightscoutTreatment>)

    /// Called when an observed `Nightscout` instance successfully fetches profile records.
    /// - Parameter nightscout: The `Nightscout` instance that performed the operation.
    /// - Parameter records: The profile records fetched.
    func nightscout(_ nightscout: Nightscout, didFetchProfileRecords records: [NightscoutProfileRecord])

    /// Called when an observed `Nightscout` instance successfully uploads profile records.
    /// - Parameter nightscout: The `Nightscout` instance that performed the operation.
    /// - Parameter records: The profile records uploaded.
    func nightscout(_ nightscout: Nightscout, didUploadProfileRecords records: Set<NightscoutProfileRecord>)

    /// Called when an observed `Nightscout` instance fails to upload profile records.
    /// - Parameter nightscout: The `Nightscout` instance that performed the operation.
    /// - Parameter records: The profile records that failed to upload.
    func nightscout(_ nightscout: Nightscout, didFailToUploadProfileRecords records: Set<NightscoutProfileRecord>)

    /// Called when an observed `Nightscout` instance successfully updates profile records.
    /// - Parameter nightscout: The `Nightscout` instance that performed the operation.
    /// - Parameter records: The profile records updated.
    func nightscout(_ nightscout: Nightscout, didUpdateProfileRecords records: Set<NightscoutProfileRecord>)

    /// Called when an observed `Nightscout` instance fails to update profile records.
    /// - Parameter nightscout: The `Nightscout` instance that performed the operation.
    /// - Parameter records: The profile records that failed to update.
    func nightscout(_ nightscout: Nightscout, didFailToUpdateProfileRecords records: Set<NightscoutProfileRecord>)

    /// Called when an observed `Nightscout` instance successfully deletes profile records.
    /// - Parameter nightscout: The `Nightscout` instance that performed the operation.
    /// - Parameter records: The profile records deleted.
    func nightscout(_ nightscout: Nightscout, didDeleteProfileRecords records: Set<NightscoutProfileRecord>)

    /// Called when an observed `Nightscout` instance fails to delete profile records.
    /// - Parameter nightscout: The `Nightscout` instance that performed the operation.
    /// - Parameter records: The profile records that failed to delete.
    func nightscout(_ nightscout: Nightscout, didFailToDeleteProfileRecords records: Set<NightscoutProfileRecord>)

    /// Called when an observed `Nightscout` instance successfully fetches device statuses.
    /// - Parameter nightscout: The `Nightscout` instance that performed the operation.
    /// - Parameter deviceStatuses: The device statuses fetched.
    func nightscout(_ nightscout: Nightscout, didFetchDeviceStatuses deviceStatuses: [NightscoutDeviceStatus])

    /// Called when an observed `Nightscout` instance encounters an error when performing an operation.
    /// - Parameter nightscout: The `Nightscout` instance that performed the operation.
    /// - Parameter error: The error encountered.
    func nightscout(_ nightscout: Nightscout, didErrorWith error: NightscoutError)
}

// MARK: - Default implementations

extension NightscoutObserver {
    public func nightscoutDidVerifyAuthorization(_ nightscout: Nightscout) { }

    public func nightscout(_ nightscout: Nightscout, didFetchStatus status: NightscoutStatus) { }

    public func nightscout(_ nightscout: Nightscout, didFetchEntries entries: [NightscoutEntry]) { }
    public func nightscout(_ nightscout: Nightscout, didUploadEntries entries: Set<NightscoutEntry>) { }
    public func nightscout(_ nightscout: Nightscout, didFailToUploadEntries entries: Set<NightscoutEntry>) { }

    public func nightscout(_ nightscout: Nightscout, didFetchTreatments treatments: [NightscoutTreatment]) { }
    public func nightscout(_ nightscout: Nightscout, didUploadTreatments treatments: Set<NightscoutTreatment>) { }
    public func nightscout(_ nightscout: Nightscout, didFailToUploadTreatments treatments: Set<NightscoutTreatment>) { }
    public func nightscout(_ nightscout: Nightscout, didUpdateTreatments treatments: Set<NightscoutTreatment>) { }
    public func nightscout(_ nightscout: Nightscout, didFailToUpdateTreatments treatments: Set<NightscoutTreatment>) { }
    public func nightscout(_ nightscout: Nightscout, didDeleteTreatments treatments: Set<NightscoutTreatment>) { }
    public func nightscout(_ nightscout: Nightscout, didFailToDeleteTreatments treatments: Set<NightscoutTreatment>) { }

    public func nightscout(_ nightscout: Nightscout, didFetchProfileRecords records: [NightscoutProfileRecord]) { }
    public func nightscout(_ nightscout: Nightscout, didUploadProfileRecords records: Set<NightscoutProfileRecord>) { }
    public func nightscout(_ nightscout: Nightscout, didFailToUploadProfileRecords records: Set<NightscoutProfileRecord>) { }
    public func nightscout(_ nightscout: Nightscout, didUpdateProfileRecords records: Set<NightscoutProfileRecord>) { }
    public func nightscout(_ nightscout: Nightscout, didFailToUpdateProfileRecords records: Set<NightscoutProfileRecord>) { }
    public func nightscout(_ nightscout: Nightscout, didDeleteProfileRecords records: Set<NightscoutProfileRecord>) { }
    public func nightscout(_ nightscout: Nightscout, didFailToDeleteProfileRecords records: Set<NightscoutProfileRecord>) { }

    public func nightscout(_ nightscout: Nightscout, didFetchDeviceStatuses deviceStatuses: [NightscoutDeviceStatus]) { }

    public func nightscout(_ nightscout: Nightscout, didErrorWith error: NightscoutError) { }
}

// MARK: - Override enforcement

// Hopefully this won't be needed in the future:
// https://forums.swift.org/t/pitch-introducing-role-keywords-to-reduce-hard-to-find-bugs/6113

/// This class exists only to ensure that `NightscoutObserver` default protocol implementations
/// are being overriden by its subclasses through compile-time enforcement of the `override` keyword.
open class _NightscoutObserver: NightscoutObserver {
    public init() { }

    open func nightscoutDidVerifyAuthorization(_ nightscout: Nightscout) { }

    open func nightscout(_ nightscout: Nightscout, didFetchStatus status: NightscoutStatus) { }

    open func nightscout(_ nightscout: Nightscout, didFetchEntries entries: [NightscoutEntry]) { }
    open func nightscout(_ nightscout: Nightscout, didUploadEntries entries: Set<NightscoutEntry>) { }
    open func nightscout(_ nightscout: Nightscout, didFailToUploadEntries entries: Set<NightscoutEntry>) { }

    open func nightscout(_ nightscout: Nightscout, didFetchTreatments treatments: [NightscoutTreatment]) { }
    open func nightscout(_ nightscout: Nightscout, didUploadTreatments treatments: Set<NightscoutTreatment>) { }
    open func nightscout(_ nightscout: Nightscout, didFailToUploadTreatments treatments: Set<NightscoutTreatment>) { }
    open func nightscout(_ nightscout: Nightscout, didUpdateTreatments treatments: Set<NightscoutTreatment>) { }
    open func nightscout(_ nightscout: Nightscout, didFailToUpdateTreatments treatments: Set<NightscoutTreatment>) { }
    open func nightscout(_ nightscout: Nightscout, didDeleteTreatments treatments: Set<NightscoutTreatment>) { }
    open func nightscout(_ nightscout: Nightscout, didFailToDeleteTreatments treatments: Set<NightscoutTreatment>) { }

    open func nightscout(_ nightscout: Nightscout, didFetchProfileRecords records: [NightscoutProfileRecord]) { }
    open func nightscout(_ nightscout: Nightscout, didUploadProfileRecords records: Set<NightscoutProfileRecord>) { }
    open func nightscout(_ nightscout: Nightscout, didFailToUploadProfileRecords records: Set<NightscoutProfileRecord>) { }
    open func nightscout(_ nightscout: Nightscout, didUpdateProfileRecords records: Set<NightscoutProfileRecord>) { }
    open func nightscout(_ nightscout: Nightscout, didFailToUpdateProfileRecords records: Set<NightscoutProfileRecord>) { }
    open func nightscout(_ nightscout: Nightscout, didDeleteProfileRecords records: Set<NightscoutProfileRecord>) { }
    open func nightscout(_ nightscout: Nightscout, didFailToDeleteProfileRecords records: Set<NightscoutProfileRecord>) { }

    open func nightscout(_ nightscout: Nightscout, didFetchDeviceStatuses deviceStatuses: [NightscoutDeviceStatus]) { }

    open func nightscout(_ nightscout: Nightscout, didErrorWith error: NightscoutError) { }
}

// MARK: - Utilities

// unfortunately, passing these by referencing `NightscoutObserver.nightscout(_:<other parameter>:)`
// causes a compile-time segfault: https://bugs.swift.org/browse/SR-7264
// TODO: update callsites in `Nightscout` to read more clearly once the above bug is fixed
typealias NightscoutObserverAction<T> = (NightscoutObserver) -> (Nightscout, T) -> Void

extension NightscoutObserver {
    func notify<T>(for result: NightscoutResult<T>, from nightscout: Nightscout,
                   ifSuccess update: NightscoutObserverAction<T>,
                   ifError errorWork: ((NightscoutObserver) -> Void)? = nil) {
        result.ifSuccess { value in update(self)(nightscout, value) }
              .ifFailure { error in
                errorWork?(self)
                self.nightscout(nightscout, didErrorWith: error)
        }
    }

    func notify<T>(for postResponse: Nightscout.PostResponse<T>, from nightscout: Nightscout,
                   withSuccesses successUpdate: @escaping NightscoutObserverAction<Set<T>>,
                   withRejections rejectionUpdate: @escaping NightscoutObserverAction<Set<T>>,
                   ifError errorWork: ((NightscoutObserver) -> Void)? = nil) {
        notify(
            for: postResponse, from: nightscout,
            ifSuccess: { observer in { nightscout, postResponsePayload in
                let (uploadedItems, rejectedItems) = postResponsePayload
                // TODO: is ignoring empty sets always desirable?
                if !uploadedItems.isEmpty {
                    successUpdate(self)(nightscout, uploadedItems)
                }
                if !rejectedItems.isEmpty {
                    rejectionUpdate(self)(nightscout, rejectedItems)
                }
            }},
            ifError: errorWork
        )
    }

    func notify<T>(for operationResult: Nightscout.OperationResult<T>, from nightscout: Nightscout,
                   withSuccesses successUpdate: @escaping NightscoutObserverAction<Set<T>>,
                   withRejections rejectionUpdate: @escaping NightscoutObserverAction<Set<T>>) {
        let (processedItems, rejections) = operationResult
        let rejectedItems = Set(rejections.map { $0.item })
        let errors = rejections.map { $0.error }

        // TODO: is ignoring empty sets always desirable?
        if !processedItems.isEmpty {
            successUpdate(self)(nightscout, processedItems)
        }
        if !rejectedItems.isEmpty {
            rejectionUpdate(self)(nightscout, rejectedItems)
        }
        // TODO: is reporting all errors here always desirable?
        // what if they're all the same `NightscoutError.invalidURL`?
        errors.forEach { self.nightscout(nightscout, didErrorWith: $0) }
    }
}

// TODO: Should observers be notified concurrently?

extension Array where Element == NightscoutObserver {
    func notify<T>(for result: NightscoutResult<T>, from nightscout: Nightscout,
                   ifSuccess update: NightscoutObserverAction<T>,
                   ifError errorWork: ((NightscoutObserver) -> Void)? = nil) {
        forEach { $0.notify(for: result, from: nightscout, ifSuccess: update, ifError: errorWork) }
    }

    func notify<T>(for postResponse: Nightscout.PostResponse<T>, from nightscout: Nightscout,
                   withSuccesses successUpdate: @escaping NightscoutObserverAction<Set<T>>,
                   withRejections rejectionUpdate: @escaping NightscoutObserverAction<Set<T>>,
                   ifError errorWork: ((NightscoutObserver) -> Void)? = nil) {
        forEach { $0.notify(for: postResponse, from: nightscout, withSuccesses: successUpdate, withRejections: rejectionUpdate, ifError: errorWork) }
    }

    func notify<T>(for operationResult: Nightscout.OperationResult<T>, from nightscout: Nightscout,
                   withSuccesses successUpdate: @escaping NightscoutObserverAction<Set<T>>,
                   withRejections rejectionUpdate: @escaping NightscoutObserverAction<Set<T>>) {
        forEach { $0.notify(for: operationResult, from: nightscout, withSuccesses: successUpdate, withRejections: rejectionUpdate) }
    }
}

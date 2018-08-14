//
//  NightscoutUploaderObserver.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 7/16/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

/// A type that observes the operations of a `NightscoutUploader` instance.
public protocol NightscoutUploaderObserver: AnyObject {
    /// Called when an observed `NightscoutUploader` instance successfully verifies authorization.
    /// - Parameter uploader: The `NightscoutUploader` instance that performed the operation.
    func uploaderDidVerifyAuthorization(_ uploader: NightscoutUploader)

    /// Called when an observed `NightscoutUploader` instance successfully uploads entries.
    /// - Parameter uploader: The `NightscoutUploader` instance that performed the operation.
    /// - Parameter entries: The entries uploaded.
    func uploader(_ uploader: NightscoutUploader, didUploadEntries entries: Set<NightscoutEntry>)

    /// Called when an observed `NightscoutUploader` instance fails to upload entries.
    /// - Parameter uploader: The `NightscoutUploader` instance that performed the operation.
    /// - Parameter entries: The entries that failed to upload.
    func uploader(_ uploader: NightscoutUploader, didFailToUploadEntries entries: Set<NightscoutEntry>)

    /// Called when an observed `NightscoutUploader` instance successfully uploads treatments.
    /// - Parameter uploader: The `NightscoutUploader` instance that performed the operation.
    /// - Parameter treatments: The treatments uploaded.
    func uploader(_ uploader: NightscoutUploader, didUploadTreatments treatments: Set<NightscoutTreatment>)

    /// Called when an observed `NightscoutUploader` instance fails to upload treatments.
    /// - Parameter uploader: The `NightscoutUploader` instance that performed the operation.
    /// - Parameter treatments: The treatments that failed to upload.
    func uploader(_ uploader: NightscoutUploader, didFailToUploadTreatments treatments: Set<NightscoutTreatment>)

    /// Called when an observed `NightscoutUploader` instance successfully updates treatments.
    /// - Parameter uploader: The `NightscoutUploader` instance that performed the operation.
    /// - Parameter treatments: The treatments updated.
    func uploader(_ uploader: NightscoutUploader, didUpdateTreatments treatments: Set<NightscoutTreatment>)

    /// Called when an observed `NightscoutUploader` instance fails to update treatments.
    /// - Parameter uploader: The `NightscoutUploader` instance that performed the operation.
    /// - Parameter treatments: The treatments that failed to update.
    func uploader(_ uploader: NightscoutUploader, didFailToUpdateTreatments treatments: Set<NightscoutTreatment>)

    /// Called when an observed `NightscoutUploader` instance successfully deletes treatments.
    /// - Parameter uploader: The `NightscoutUploader` instance that performed the operation.
    /// - Parameter treatments: The treatments deleted.
    func uploader(_ uploader: NightscoutUploader, didDeleteTreatments treatments: Set<NightscoutTreatment>)

    /// Called when an observed `NightscoutUploader` instance fails to delete treatments.
    /// - Parameter uploader: The `NightscoutUploader` instance that performed the operation.
    /// - Parameter treatments: The treatments that failed to delete.
    func uploader(_ uploader: NightscoutUploader, didFailToDeleteTreatments treatments: Set<NightscoutTreatment>)

    /// Called when an observed `NightscoutUploader` instance successfully uploads profile records.
    /// - Parameter uploader: The `NightscoutUploader` instance that performed the operation.
    /// - Parameter records: The profile records uploaded.
    func uploader(_ uploader: NightscoutUploader, didUploadProfileRecords records: Set<NightscoutProfileRecord>)

    /// Called when an observed `NightscoutUploader` instance fails to upload profile records.
    /// - Parameter uploader: The `NightscoutUploader` instance that performed the operation.
    /// - Parameter records: The profile records that failed to upload.
    func uploader(_ uploader: NightscoutUploader, didFailToUploadProfileRecords records: Set<NightscoutProfileRecord>)

    /// Called when an observed `NightscoutUploader` instance successfully updates profile records.
    /// - Parameter uploader: The `NightscoutUploader` instance that performed the operation.
    /// - Parameter records: The profile records updated.
    func uploader(_ uploader: NightscoutUploader, didUpdateProfileRecords records: Set<NightscoutProfileRecord>)

    /// Called when an observed `NightscoutUploader` instance fails to update profile records.
    /// - Parameter uploader: The `NightscoutUploader` instance that performed the operation.
    /// - Parameter records: The profile records that failed to update.
    func uploader(_ uploader: NightscoutUploader, didFailToUpdateProfileRecords records: Set<NightscoutProfileRecord>)

    /// Called when an observed `NightscoutUploader` instance successfully deletes profile records.
    /// - Parameter uploader: The `NightscoutUploader` instance that performed the operation.
    /// - Parameter records: The profile records deleted.
    func uploader(_ uploader: NightscoutUploader, didDeleteProfileRecords records: Set<NightscoutProfileRecord>)

    /// Called when an observed `NightscoutUploader` instance fails to delete profile records.
    /// - Parameter uploader: The `NightscoutUploader` instance that performed the operation.
    /// - Parameter records: The profile records that failed to delete.
    func uploader(_ uploader: NightscoutUploader, didFailToDeleteProfileRecords records: Set<NightscoutProfileRecord>)

    /// Called when an observed `NightscoutUploader` instance encounters an error when performing an operation.
    /// - Parameter uploader: The `NightscoutUploader` instance that performed the operation.
    /// - Parameter error: The error encountered.
    func uploader(_ uploader: NightscoutUploader, didErrorWith error: NightscoutError)
}

// MARK: - Default Implementations

extension NightscoutUploaderObserver {
    public func uploaderDidVerifyAuthorization(_ uploader: NightscoutUploader) { }
    public func uploader(_ uploader: NightscoutUploader, didUploadEntries entries: Set<NightscoutEntry>) { }
    public func uploader(_ uploader: NightscoutUploader, didFailToUploadEntries entries: Set<NightscoutEntry>) { }
    public func uploader(_ uploader: NightscoutUploader, didUploadTreatments treatments: Set<NightscoutTreatment>) { }
    public func uploader(_ uploader: NightscoutUploader, didFailToUploadTreatments treatments: Set<NightscoutTreatment>) { }
    public func uploader(_ uploader: NightscoutUploader, didUpdateTreatments treatments: Set<NightscoutTreatment>) { }
    public func uploader(_ uploader: NightscoutUploader, didFailToUpdateTreatments treatments: Set<NightscoutTreatment>) { }
    public func uploader(_ uploader: NightscoutUploader, didDeleteTreatments treatments: Set<NightscoutTreatment>) { }
    public func uploader(_ uploader: NightscoutUploader, didFailToDeleteTreatments treatments: Set<NightscoutTreatment>) { }
    public func uploader(_ uploader: NightscoutUploader, didUploadProfileRecords records: Set<NightscoutProfileRecord>) { }
    public func uploader(_ uploader: NightscoutUploader, didFailToUploadProfileRecords records: Set<NightscoutProfileRecord>) { }
    public func uploader(_ uploader: NightscoutUploader, didUpdateProfileRecords records: Set<NightscoutProfileRecord>) { }
    public func uploader(_ uploader: NightscoutUploader, didFailToUpdateProfileRecords records: Set<NightscoutProfileRecord>) { }
    public func uploader(_ uploader: NightscoutUploader, didDeleteProfileRecords records: Set<NightscoutProfileRecord>) { }
    public func uploader(_ uploader: NightscoutUploader, didFailToDeleteProfileRecords records: Set<NightscoutProfileRecord>) { }
    public func uploader(_ uploader: NightscoutUploader, didErrorWith error: NightscoutError) { }
}


// TODO: Unify the below API with `NightscoutDownloaderObserver`, likely through the use of protocols.

internal typealias NightscoutUploaderObserverAction<Payload> = (NightscoutUploaderObserver, Payload) -> Void

extension NightscoutUploaderObserver {
    typealias Action<Payload> = NightscoutUploaderObserverAction<Payload>

    func notify<T>(
        for result: NightscoutResult<T>,
        from uploader: NightscoutUploader,
        ifSuccess update: Action<T>,
        ifError errorWork: Action<NightscoutError>? = nil
    ) {
        switch result {
        case .success(let value):
            update(self, value)
        case .failure(let error):
            errorWork?(self, error)
            self.uploader(uploader, didErrorWith: error)
        }
    }

    func notify<T>(
        for postResponse: NightscoutUploader.PostResponse<T>,
        from uploader: NightscoutUploader,
        withSuccesses successUpdate: @escaping Action<Set<T>>,
        withRejections rejectionUpdate: @escaping Action<Set<T>>,
        ifError errorWork: Action<NightscoutError>? = nil
    ) {
        notify(
            for: postResponse,
            from: uploader,
            ifSuccess: { observer, postResponsePayload in
                let (uploadedItems, rejectedItems) = postResponsePayload
                // TODO: Is ignoring empty sets always desirable?
                if !uploadedItems.isEmpty {
                    successUpdate(self, uploadedItems)
                }
                if !rejectedItems.isEmpty {
                    rejectionUpdate(self, rejectedItems)
                }
        },
            ifError: errorWork
        )
    }

    func notify<T>(
        for operationResult: NightscoutUploader.OperationResult<T>,
        from uploader: NightscoutUploader,
        withSuccesses successUpdate: Action<Set<T>>,
        withRejections rejectionUpdate: Action<Set<T>>
    ) {
        let (processedItems, rejections) = operationResult
        let rejectedItems = Set(rejections.map { $0.item })
        let errors = rejections.map { $0.error }

        // TODO: is ignoring empty sets always desirable?
        if !processedItems.isEmpty {
            successUpdate(self, processedItems)
        }
        if !rejectedItems.isEmpty {
            rejectionUpdate(self, rejectedItems)
        }
        // TODO: is reporting all errors here always desirable?
        // what if they're all the same `NightscoutError.invalidURL`?
        errors.forEach { self.uploader(uploader, didErrorWith: $0) }
    }
}

extension RandomAccessCollection where Element == NightscoutUploaderObserver {
    func concurrentlyNotify<T>(
        for result: NightscoutResult<T>,
        from uploader: NightscoutUploader,
        ifSuccess update: NightscoutUploaderObserverAction<T>,
        ifError errorWork: NightscoutUploaderObserverAction<NightscoutError>? = nil
    ) {
        concurrentForEach { observer in
            observer.notify(for: result, from: uploader, ifSuccess: update, ifError: errorWork)
        }
    }

    func concurrentlyNotify<T>(
        for postResponse: NightscoutUploader.PostResponse<T>,
        from uploader: NightscoutUploader,
        withSuccesses successUpdate: @escaping NightscoutUploaderObserverAction<Set<T>>,
        withRejections rejectionUpdate: @escaping NightscoutUploaderObserverAction<Set<T>>,
        ifError errorWork: NightscoutUploaderObserverAction<NightscoutError>?
    ) {
        concurrentForEach { observer in
            observer.notify(for: postResponse, from: uploader, withSuccesses: successUpdate, withRejections: rejectionUpdate, ifError: errorWork)
        }
    }

    func concurrentlyNotify<T>(
        for operationResult: NightscoutUploader.OperationResult<T>,
        from uploader: NightscoutUploader,
        withSuccesses successUpdate: NightscoutUploaderObserverAction<Set<T>>,
        withRejections rejectionUpdate: NightscoutUploaderObserverAction<Set<T>>
    ) {
        concurrentForEach { observer in
            observer.notify(for: operationResult, from: uploader, withSuccesses: successUpdate, withRejections: rejectionUpdate)
        }
    }
}

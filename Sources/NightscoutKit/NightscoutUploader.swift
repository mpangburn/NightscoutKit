//
//  NightscoutUploader.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 7/16/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Foundation
import Oxygen


/// Uploads, updates, and deletes data from a user-hosted Nightscout server.
/// Provides API for manipulating entries, treatments, and profile records.
public final class NightscoutUploader: AtomicObservable {
    public typealias Observer = NightscoutUploaderObserver

    /// The credentials used in accessing the Nightscout site.
    public internal(set) var credentials: NightscoutUploaderCredentials

    private let router: NightscoutRouter

    private var sessions = URLSessionProvider()

    private let queues = QueueProvider()

    internal var _observers: Atomic<[ObjectIdentifier: Weak<NightscoutUploaderObserver>]> = Atomic([:])

    /// Creates a new uploader instance using the given credentials.
    /// - Parameter credentials: The validated credentials to use in accessing the Nightscout site.
    /// - Returns: A new uploader instance using the given credentials.
    public init(credentials: NightscoutUploaderCredentials) {
        self.credentials = credentials
        self.router = NightscoutRouter(url: credentials.url, apiSecret: credentials.apiSecret)
    }
}

extension NightscoutUploader {
    private typealias APIEndpoint = NightscoutAPIEndpoint
    private typealias QueryItem = NightscoutQueryItem

    private final class QueueProvider {
        private lazy var treatmentsQueue = DispatchQueue(label: "com.mpangburn.nightscoutkit.treatments")
        private lazy var profilesQueue = DispatchQueue(label: "com.mpangburn.nightscoutkit.profiles")

        func dispatchQueue(for endpoint: APIEndpoint) -> DispatchQueue {
            switch endpoint {
            case .treatments:
                return treatmentsQueue
            case .profiles:
                return profilesQueue
            default:
                fatalError("Unexpected dispatch queue request for endpoint \(endpoint)")
            }
        }
    }
}

// MARK: - Public API

extension NightscoutUploader {
    /// Describes a response to a Nightscout post request.
    /// A successful result contains a tuple containing the successfully uploaded items and the rejected items.
    public typealias PostResponse<Payload: Hashable> = NightscoutResult<(uploadedItems: Set<Payload>, rejectedItems: Set<Payload>)>

    /// A tuple containing the set of items successfully processed by an operation and the set of rejections.
    public typealias OperationResult<Payload: Hashable> = (processedItems: Set<Payload>, rejections: Set<Rejection<Payload>>)

    /// Describes the item for which an operation failed and the error produced.
    public struct Rejection<Payload: Hashable>: Hashable {
        /// The item for which the operation failed.
        public let item: Payload

        /// The error that produced the operation failure.
        public let error: NightscoutError

        public static func == (lhs: Rejection, rhs: Rejection) -> Bool {
            return lhs.item == rhs.item // ignore the error
        }

        public var hashValue: Int {
            return item.hashValue // ignore the error
        }
    }
}

extension NightscoutUploader {
    /// Verifies that the instance is authorized to upload, update, and delete entities.
    /// - Parameter completion: The completion handler to be called upon completing the operation.
    ///                         Observers will be notified of the result of this operation before `completion` is invoked.
    /// - Parameter error: The error that occurred in verifying authorization. `nil` indicates success.
    public func verifyAuthorization(completion: ((_ error: NightscoutError?) -> Void)? = nil) {
        guard let request = router.configureURLRequest(for: .authorization) else {
            completion?(.invalidURL)
            return
        }

        NightscoutDownloader.fetchData(from: .authorization, with: request, sessions: sessions) { result in
            self.observers.concurrentlyNotify(
                for: result, from: self,
                ifSuccess: { observer, _ in observer.uploaderDidVerifyAuthorization(self) }
            )
            completion?(result.error)
        }
    }

    /// Uploads the blood glucose entries.
    /// - Parameter entries: The blood glucose entries to upload.
    /// - Parameter completion: The completion handler to be called upon completing the operation.
    ///                         Observers will be notified of the result of this operation before `completion` is invoked.
    /// - Parameter result: The result of the operation. A successful result contains a tuple containing the successfully uploaded entries and the rejected entries.
    public func uploadEntries(
        _ entries: [NightscoutEntry],
        completion: ((_ result: PostResponse<NightscoutEntry>) -> Void)? = nil
    ) {
        post(entries, to: .entries) { (result: PostResponse<NightscoutEntry>) in
            self.observers.concurrentlyNotify(
                for: result, from: self,
                withSuccesses: { observer, entries in observer.uploader(self, didUploadEntries: entries) },
                withRejections: { observer, entries in observer.uploader(self, didFailToUploadEntries: entries) },
                ifError: { observer, error in observer.uploader(self, didFailToUploadEntries: Set(entries)) }
            )
            completion?(result)
        }
    }

    // FIXME: entry deletion fails--but why?
    /* public */ func deleteEntries(
        _ entries: [NightscoutEntry],
        completion: @escaping (_ operationResult: OperationResult<NightscoutEntry>) -> Void
    ) {
        // TODO: Observer API once this is fixed
        fatalError("\(#function) is unimplemented")
    }

    /// Uploads the treatments.
    /// - Parameter treatments: The treatments to upload.
    /// - Parameter completion: The completion handler to be called upon completing the operation.
    ///                         Observers will be notified of the result of this operation before `completion` is invoked.
    /// - Parameter result: The result of the operation. A successful result contains a tuple containing the successfully uploaded treatments and the rejected treatments.
    public func uploadTreatments(_ treatments: [NightscoutTreatment],
                                 completion: ((_ result: PostResponse<NightscoutTreatment>) -> Void)? = nil) {
        post(treatments, to: .treatments) { (result: PostResponse<NightscoutTreatment>) in
            self.observers.concurrentlyNotify(
                for: result, from: self,
                withSuccesses: { observer, treatments in observer.uploader(self, didUploadTreatments: treatments) },
                withRejections: { observer, treatments in observer.uploader(self, didFailToUploadTreatments: treatments) },
                ifError: { observer, error in observer.uploader(self, didFailToUploadTreatments: Set(treatments)) }
            )
            completion?(result)
        }
    }

    /// Updates the treatments.
    /// If treatment dates are modified, Nightscout will post the treatments as duplicates. In these cases, it is recommended to delete these treatments
    /// and reupload them rather than update them.
    /// - Parameter treatments: The treatments to update.
    /// - Parameter completion: The completion handler to be called upon completing the operation.
    ///                         Observers will be notified of the result of this operation before `completion` is invoked.
    /// - Parameter operationResult: The result of the operation, which contains both the successfully updated treatments and the rejections.
    public func updateTreatments(
        _ treatments: [NightscoutTreatment],
        completion: ((_ operationResult: OperationResult<NightscoutTreatment>) -> Void)? = nil
    ) {
        put(treatments, to: .treatments) { (operationResult: OperationResult<NightscoutTreatment>) in
            self.observers.concurrentlyNotify(
                for: operationResult, from: self,
                withSuccesses: { observer, treatments in observer.uploader(self, didUpdateTreatments: treatments) },
                withRejections: { observer, treatments in observer.uploader(self, didFailToUpdateTreatments: treatments) }
            )
            completion?(operationResult)
        }
    }

    /// Deletes the treatments.
    /// - Parameter treatments: The treatments to delete.
    /// - Parameter completion: The completion handler to be called upon completing the operation.
    ///                         Observers will be notified of the result of this operation before `completion` is invoked.
    /// - Parameter operationResult: The result of the operation, which contains both the successfully deleted treatments and the rejections.
    public func deleteTreatments(
        _ treatments: [NightscoutTreatment],
        completion: ((_ operationResult: OperationResult<NightscoutTreatment>) -> Void)? = nil
    ) {
        delete(treatments, from: .treatments) { (operationResult: OperationResult<NightscoutTreatment>) in
            self.observers.concurrentlyNotify(
                for: operationResult, from: self,
                withSuccesses: { observer, treatments in observer.uploader(self, didDeleteTreatments: treatments) },
                withRejections: { observer, treatments in observer.uploader(self, didFailToDeleteTreatments: treatments) }
            )
            completion?(operationResult)
        }
    }

    /// Uploads the profile records.
    /// - Parameter records: The profile records to upload.
    /// - Parameter completion: The completion handler to be called upon completing the operation.
    ///                         Observers will be notified of the result of this operation before `completion` is invoked.
    /// - Parameter result: The result of the operation. A successful result contains a tuple containing the successfully uploaded records and the rejected records.
    public func uploadProfileRecords(
        _ records: [NightscoutProfileRecord],
        completion: ((_ result: PostResponse<NightscoutProfileRecord>) -> Void)? = nil
    ) {
        post(records, to: .profiles) { (result: PostResponse<NightscoutProfileRecord>) in
            self.observers.concurrentlyNotify(
                for: result, from: self,
                withSuccesses: { observer, records in observer.uploader(self, didUploadProfileRecords: records) },
                withRejections: { observer, records in observer.uploader(self, didFailToUploadProfileRecords: records) },
                ifError: { observer, error in observer.uploader(self, didFailToUploadProfileRecords: Set(records)) }
            )
            completion?(result)
        }
    }

    /// Updates the profile records.
    /// If profile record dates are modified, Nightscout will post the profile records as duplicates. In these cases, it is recommended to delete these records
    /// and reupload them rather than update them.
    /// - Parameter records: The profile records to update.
    /// - Parameter completion: The completion handler to be called upon completing the operation.
    ///                         Observers will be notified of the result of this operation before `completion` is invoked.
    /// - Parameter operationResult: The result of the operation, which contains both the successfully updated records and the rejections.
    public func updateProfileRecords(
        _ records: [NightscoutProfileRecord],
        completion: ((_ operationResult: OperationResult<NightscoutProfileRecord>) -> Void)? = nil
    ) {
        put(records, to: .profiles) { (operationResult: OperationResult<NightscoutProfileRecord>) in
            self.observers.concurrentlyNotify(
                for: operationResult, from: self,
                withSuccesses: { observer, records in observer.uploader(self, didUpdateProfileRecords: records) },
                withRejections: { observer, records in observer.uploader(self, didFailToUpdateProfileRecords: records) }
            )
            completion?(operationResult)
        }
    }

    /// Deletes the profile records.
    /// - Parameter records: The profile records to delete.
    /// - Parameter completion: The completion handler to be called upon completing the operation.
    ///                         Observers will be notified of the result of this operation before `completion` is invoked.
    /// - Parameter operationResult: The result of the operation, which contains both the successfully deleted records and the rejections.
    public func deleteProfileRecords(
        _ records: [NightscoutProfileRecord],
        completion: ((_ operationResult: OperationResult<NightscoutProfileRecord>) -> Void)? = nil
    ) {
        delete(records, from: .profiles) { (operationResult: OperationResult<NightscoutProfileRecord>) in
            self.observers.concurrentlyNotify(
                for: operationResult, from: self,
                withSuccesses: { observer, records in observer.uploader(self, didDeleteProfileRecords: records) },
                withRejections: { observer, records in observer.uploader(self, didFailToDeleteProfileRecords: records) }
            )
            completion?(operationResult)
        }
    }
}

// MARK: - Private API

extension NightscoutUploader {
    private func uploadData(
        _ data: Data,
        to endpoint: APIEndpoint,
        with request: URLRequest,
        completion: @escaping (NightscoutResult<Data>) -> Void
    ) {
        let session = sessions[endpoint]
        let task = session.uploadTask(with: request, from: data) { data, response, error in
            guard error == nil else {
                completion(.failure(.uploadError(error!)))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.notAnHTTPURLResponse))
                return
            }

            guard let data = data else {
                fatalError("The data task produced no error, but also returned no data. These states are mutually exclusive.")
            }

            guard httpResponse.statusCode == 200 else {
                switch httpResponse.statusCode {
                case 401:
                    completion(.failure(.unauthorized))
                default:
                    let body = String(data: data, encoding: .utf8)!
                    completion(.failure(.httpError(statusCode: httpResponse.statusCode, body: body)))
                }
                return
            }

            completion(.success(data))
        }

        task.resume()
    }

    private func upload<Payload: JSONRepresentable, Response: JSONParseable>(
        _ item: Payload,
        to endpoint: APIEndpoint,
        httpMethod: HTTPMethod,
        completion: @escaping (NightscoutResult<Response>) -> Void
    ) {
        guard let request = router.configureURLRequest(for: endpoint, httpMethod: httpMethod) else {
            completion(.failure(.invalidURL))
            return
        }

        let data: Data
        do {
            data = try item.data()
        } catch {
            completion(.failure(.jsonParsingError(error)))
            return
        }

        // TODO: Clean this up with the Oxygen Result API
        uploadData(data, to: endpoint, with: request) { result in
            switch result {
            case .success(let data):
                do {
                    guard let response = try Response.parse(fromData: data) else {
                        completion(.failure(.dataParsingFailure(data)))
                        return
                    }
                    completion(.success(response))
                } catch {
                    completion(.failure(.jsonParsingError(error)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func post<Payload: JSONRepresentable & JSONParseable>(
        _ items: [Payload],
        to endpoint: APIEndpoint,
        completion: @escaping (PostResponse<Payload>) -> Void
    ) {
        upload(items, to: endpoint, httpMethod: .post) { (result: NightscoutResult<[Payload]>) in
            let postResponse: PostResponse<Payload> = result.map { uploadedItems in
                let uploadedItems = Set(uploadedItems)
                let rejectedItems = Set(items).subtracting(uploadedItems)
                return (uploadedItems: uploadedItems, rejectedItems: rejectedItems)
            }
            completion(postResponse)
        }
    }

    private func put<Payload: JSONRepresentable & JSONParseable>(
        _ items: [Payload],
        to endpoint: APIEndpoint,
        completion: @escaping (OperationResult<Payload>) -> Void
    ) {
        concurrentPerform(_put, items: items, endpoint: endpoint, completion: completion)
    }

    private func _put<Payload: JSONRepresentable & JSONParseable>(
        _ item: Payload,
        to endpoint: APIEndpoint,
        completion: @escaping (NightscoutError?) -> Void
    ) {
        upload(item, to: endpoint, httpMethod: .put) { (result: NightscoutResult<AnyJSON>) in
            completion(result.error)
        }
    }

    private func delete<Payload: NightscoutIdentifiable>(
        _ items: [Payload],
        from endpoint: APIEndpoint,
        completion: @escaping (OperationResult<Payload>) -> Void
    ) {
        concurrentPerform(_delete, items: items, endpoint: endpoint, completion: completion)
    }

    private func _delete<Payload: NightscoutIdentifiable>(
        _ item: Payload,
        from endpoint: APIEndpoint,
        completion: @escaping (NightscoutError?) -> Void
    ) {
        guard var request = router.configureURLRequest(for: endpoint, httpMethod: .delete) else {
            completion(.invalidURL)
            return
        }

        request.url?.appendPathComponent(item.id.value)
        NightscoutDownloader.fetchData(from: endpoint, with: request, sessions: sessions) { result in
            completion(result.error)
        }
    }

    private typealias Operation<T> = (
        _ item: T,
        _ endpoint: APIEndpoint,
        _ completion: @escaping (NightscoutError?) -> Void
        ) -> Void

    private func concurrentPerform<T>(
        _ operation: Operation<T>,
        items: [T],
        endpoint: APIEndpoint,
        completion: @escaping (OperationResult<T>) -> Void
    ) {
        let rejections: Atomic<Set<Rejection<T>>> = Atomic([])
        let operationGroup = DispatchGroup()

        for item in items {
            operationGroup.enter()
            operation(item, endpoint) { error in
                if let error = error {
                    rejections.modify { rejections in
                        let rejection = Rejection(item: item, error: error)
                        rejections.insert(rejection)
                    }
                }
                operationGroup.leave()
            }
        }

        let queue = queues.dispatchQueue(for: endpoint)
        operationGroup.notify(queue: queue) {
            let rejectionsSet = rejections.value
            let processedSet = Set(items).subtracting(rejectionsSet.map { $0.item })
            let operationResult: OperationResult = (processedItems: processedSet, rejections: rejectionsSet)
            completion(operationResult)
        }
    }
}

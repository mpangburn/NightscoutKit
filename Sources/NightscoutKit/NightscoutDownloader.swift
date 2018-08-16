//
//  NightscoutDownloader.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 6/25/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Foundation


/// Retrieves data from a user-hosted Nightscout server.
/// Provides API for fetching blood gluocse entries, treatments, profile records,
/// device statuses, and the site status and settings.
public final class NightscoutDownloader: ThreadSafeObservable {
    public typealias Observer = NightscoutDownloaderObserver

    /// The credentials used in accessing the Nightscout site.
    public let credentials: NightscoutDownloaderCredentials

    private let router: NightscoutRouter

    private let sessions = URLSessionProvider()

    /// The queue on which to perform the completion of a snapshot call.
    private let snapshotQueue = DispatchQueue(label: "com.mpangburn.nightscoutkit.snapshotqueue")

    internal var _observers: ThreadSafe<[ObjectIdentifier: WeakBox<NightscoutDownloaderObserver>]> = ThreadSafe([:])

    /// Creates a new downloader instance using the given credentials.
    /// - Parameter credentials: The validated credentials to use in accessing the Nightscout site.
    /// - Returns: A new downloader instance using the given credentials.
    public init(credentials: NightscoutDownloaderCredentials) {
        self.credentials = credentials
        self.router = NightscoutRouter(url: credentials.url)
    }
}

// MARK: - Public API

extension NightscoutDownloader {
    /// Takes a snapshot of the current Nightscout site.
    /// - Parameter recentBloodGlucoseEntryCount: The number of recent blood glucose entries to fetch. Defaults to 10.
    /// - Parameter recentTreatmentCount: The number of recent treatments to fetch. Defaults to 10.
    /// - Parameter recentDeviceStatusCount: The number of recent device statuses to fetch. Defaults to 10.
    /// - Parameter completion: The completion handler to be called upon completing the operation.
    ///                         Observers will be notified of the result of this operation before `completion` is invoked.
    /// - Parameter result: The result of the operation.
    public func snapshot(
        recentBloodGlucoseEntryCount: Int = 10,
        recentTreatmentCount: Int = 10,
        recentDeviceStatusCount: Int = 10,
        completion: @escaping (_ result: NightscoutResult<NightscoutSnapshot>) -> Void
    ) {
        let timestamp = Date()
        var status: NightscoutStatus?
        var deviceStatuses: [NightscoutDeviceStatus] = []
        var entries: [NightscoutEntry] = []
        var treatments: [NightscoutTreatment] = []
        var profileRecords: [NightscoutProfileRecord] = []
        let error: ThreadSafe<NightscoutError?> = ThreadSafe(nil)

        let snapshotGroup = DispatchGroup()

        snapshotGroup.enter()
        fetchStatus { result in
            switch result {
            case .success(let fetchedStatus):
                status = fetchedStatus
            case .failure(let err):
                error.atomicallyAssign(to: err)
            }
            snapshotGroup.leave()
        }

        snapshotGroup.enter()
        fetchMostRecentDeviceStatuses(count: recentDeviceStatusCount) { result in
            switch result {
            case .success(let fetchedDeviceStatuses):
                deviceStatuses = fetchedDeviceStatuses
            case .failure(let err):
                error.atomicallyAssign(to: err)
            }
            snapshotGroup.leave()
        }

        snapshotGroup.enter()
        fetchProfileRecords { result in
            switch result {
            case .success(let fetchedProfileRecords):
                profileRecords = fetchedProfileRecords
            case .failure(let err):
                error.atomicallyAssign(to: err)
            }
            snapshotGroup.leave()
        }

        snapshotGroup.enter()
        fetchMostRecentEntries(count: recentBloodGlucoseEntryCount) { result in
            switch result {
            case .success(let fetchedBloodGlucoseEntries):
                entries = fetchedBloodGlucoseEntries
            case .failure(let err):
                error.atomicallyAssign(to: err)
            }
            snapshotGroup.leave()
        }

        snapshotGroup.enter()
        fetchMostRecentTreatments(count: recentTreatmentCount) { result in
            switch result {
            case .success(let fetchedTreatments):
                treatments = fetchedTreatments
            case .failure(let err):
                error.atomicallyAssign(to: err)
            }
            snapshotGroup.leave()
        }

        snapshotGroup.notify(queue: snapshotQueue) {
            // There's a race condition with errors here, but if any fetch request fails, we'll report an error--it doesn't matter which.
            guard error.value == nil else {
                completion(.failure(error.value!))
                return
            }

            let snapshot = NightscoutSnapshot(timestamp: timestamp, status: status!, entries: entries,
                                              treatments: treatments, profileRecords: profileRecords, deviceStatuses: deviceStatuses)
            completion(.success(snapshot))
        }
    }

    /// Fetches the status of the Nightscout site.
    /// - Parameter completion: The completion handler to be called upon completing the operation.
    ///                         Observers will be notified of the result of this operation before `completion` is invoked.
    /// - Parameter result: The result of the operation.
    public func fetchStatus(completion: ((_ result: NightscoutResult<NightscoutStatus>) -> Void)? = nil) {
        fetch(from: .status) { (result: NightscoutResult<NightscoutStatus>) in
            self.observers.concurrentlyNotify(for: result, from: self, ifSuccess: { observer, payload in
                observer.downloader(self, didFetchStatus: payload)
            })
            completion?(result)
        }
    }

    /// Fetches the most recent blood glucose entries.
    /// - Parameter count: The number of recent blood glucose entries to fetch. Defaults to 10.
    /// - Parameter completion: The completion handler to be called upon completing the operation.
    ///                         Observers will be notified of the result of this operation before `completion` is invoked.
    /// - Parameter result: The result of the operation.
    public func fetchMostRecentEntries(
        count: Int = 10,
        completion: ((_ result: NightscoutResult<[NightscoutEntry]>) -> Void)? = nil
    ) {
        let queryItems: [QueryItem] = [.count(count)]
        fetch(from: .entries, queryItems: queryItems) { (result: NightscoutResult<[NightscoutEntry]>) in
            self.observers.concurrentlyNotify(for: result, from: self, ifSuccess: { observer, entries in
                observer.downloader(self, didFetchEntries: entries)
            })
            completion?(result)
        }
    }

    /// Fetches the blood glucose entries from within the specified `DateInterval`.
    /// - Parameter interval: The interval from which blood glucose entries should be fetched.
    /// - Parameter maxCount: The maximum number of blood glucose entries to fetch. Defaults to `2 ** 31`, where `**` is exponentiation.
    /// - Parameter completion: The completion handler to be called upon completing the operation.
    ///                         Observers will be notified of the result of this operation before `completion` is invoked.
    /// - Parameter result: The result of the operation.
    public func fetchEntries(
        fromInterval interval: DateInterval,
        maxCount: Int = 2 << 31,
        completion: ((_ result: NightscoutResult<[NightscoutEntry]>) -> Void)? = nil
    ) {
        let queryItems = QueryItem.entryDates(from: interval) + [.count(maxCount)]
        fetch(from: .entries, queryItems: queryItems) { (result: NightscoutResult<[NightscoutEntry]>) in
            self.observers.concurrentlyNotify(for: result, from: self, ifSuccess: { observer, entries in
                observer.downloader(self, didFetchEntries: entries)
            })
            completion?(result)
        }
    }

    /// Fetches the most recent treatments.
    /// - Parameter eventKind: The event kind to match. If this argument is `nil`, all event kinds are included. Defaults to `nil`.
    /// - Parameter count: The number of recent treatments to fetch. Defaults to 10.
    /// - Parameter completion: The completion handler to be called upon completing the operation.
    ///                         Observers will be notified of the result of this operation before `completion` is invoked.
    /// - Parameter result: The result of the operation.
    public func fetchMostRecentTreatments(
        matching eventKind: NightscoutTreatment.EventType.Kind? = nil,
        count: Int = 10,
        completion: ((_ result: NightscoutResult<[NightscoutTreatment]>) -> Void)? = nil
    ) {
        var queryItems: [QueryItem] = [.count(count)]
        if let eventKindQueryItem = eventKind.map(QueryItem.treatmentEventType(matching:)) {
            queryItems.append(eventKindQueryItem)
        }
        fetch(from: .treatments, queryItems: queryItems) { (result: NightscoutResult<[NightscoutTreatment]>) in
            self.observers.concurrentlyNotify(for: result, from: self, ifSuccess: { observer, treatments in
                observer.downloader(self, didFetchTreatments: treatments)
            })
            completion?(result)
        }
    }

    /// Fetches the treatments meeting the given specifications.
    /// - Parameter eventKind: The event kind to match. If this argument is `nil`, all event kinds are included. Defaults to `nil`.
    /// - Parameter interval: The interval from which treatments should be fetched.
    /// - Parameter maxCount: The maximum number of treatments to fetch. Defaults to `2 ** 31`, where `**` is exponentiation.
    /// - Parameter completion: The completion handler to be called upon completing the operation.
    ///                         Observers will be notified of the result of this operation before `completion` is invoked.
    /// - Parameter result: The result of the operation.
    public func fetchTreatments(
        matching eventKind: NightscoutTreatment.EventType.Kind? = nil,
        fromInterval interval: DateInterval,
        maxCount: Int = 2 << 31,
        completion: ((_ result: NightscoutResult<[NightscoutTreatment]>) -> Void)? = nil
    ) {
        var queryItems = QueryItem.treatmentDates(from: interval) + [.count(maxCount)]
        eventKind.map(QueryItem.treatmentEventType(matching:)).map { queryItems.append($0) }
        fetch(from: .treatments, queryItems: queryItems) { (result: NightscoutResult<[NightscoutTreatment]>) in
            self.observers.concurrentlyNotify(for: result, from: self, ifSuccess: { observer, treatments in
                observer.downloader(self, didFetchTreatments: treatments)
            })
            completion?(result)
        }
    }

    /// Fetches the profile records.
    /// - Parameter completion: The completion handler to be called upon completing the operation.
    ///                         Observers will be notified of the result of this operation before `completion` is invoked.
    /// - Parameter result: The result of the operation.
    public func fetchProfileRecords(completion: ((_ result: NightscoutResult<[NightscoutProfileRecord]>) -> Void)? = nil) {
        fetch(from: .profiles) { (result: NightscoutResult<[NightscoutProfileRecord]>) in
            self.observers.concurrentlyNotify(for: result, from: self, ifSuccess: { observer, records in
                observer.downloader(self, didFetchProfileRecords: records)
            })
            completion?(result)
        }
    }

    /// Fetches the most recent device statuses.
    /// - Parameter count: The number of recent device statuses to fetch. Defaults to 10.
    /// - Parameter completion: The completion handler to be called upon completing the operation.
    ///                         Observers will be notified of the result of this operation before `completion` is invoked.
    /// - Parameter result: The result of the operation.
    public func fetchMostRecentDeviceStatuses(
        count: Int = 10,
        completion: ((_ result: NightscoutResult<[NightscoutDeviceStatus]>) -> Void)? = nil
    ) {
        let queryItems: [QueryItem] = [.count(count)]
        fetch(from: .deviceStatus, queryItems: queryItems) { (result: NightscoutResult<[NightscoutDeviceStatus]>) in
            self.observers.concurrentlyNotify(for: result, from: self, ifSuccess: { observer, deviceStatuses in
                observer.downloader(self, didFetchDeviceStatuses: deviceStatuses)
            })
            completion?(result)
        }
    }

    /// Fetches the device statuses from within the specified `DateInterval`.
    /// - Parameter interval: The interval from which device statuses should be fetched.
    /// - Parameter maxCount: The maximum number of device statuses to fetch. Defaults to `2 ** 31`, where `**` is exponentiation.
    /// - Parameter completion: The completion handler to be called upon completing the operation.
    ///                         Observers will be notified of the result of this operation before `completion` is invoked.
    /// - Parameter result: The result of the operation.
    public func fetchDeviceStatuses(
        fromInterval interval: DateInterval,
        maxCount: Int = 2 << 31,
        completion: ((_ result: NightscoutResult<[NightscoutDeviceStatus]>) -> Void)? = nil
    ) {
        let queryItems = QueryItem.deviceStatusDates(from: interval) + [.count(maxCount)]
        fetch(from: .deviceStatus, queryItems: queryItems) { (result: NightscoutResult<[NightscoutDeviceStatus]>) in
            self.observers.concurrentlyNotify(for: result, from: self, ifSuccess: { observer, payload in
                observer.downloader(self, didFetchDeviceStatuses: payload)
            })
            completion?(result)
        }
    }
}

// MARK: - Private API

extension NightscoutDownloader {
    internal typealias APIEndpoint = NightscoutAPIEndpoint
    internal typealias QueryItem = NightscoutQueryItem

    internal static func fetchData(
        from endpoint: APIEndpoint,
        with request: URLRequest,
        sessions: URLSessionProvider,
        completion: @escaping (NightscoutResult<Data>) -> Void
    ) {
        let session = sessions.urlSession(for: endpoint)
        let task = session.dataTask(with: request) { data, response, error in
            guard error == nil else {
                completion(.failure(.fetchError(error!)))
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

    private func fetchData(
        from endpoint: APIEndpoint,
        with request: URLRequest,
        completion: @escaping (NightscoutResult<Data>) -> Void
    ) {
        NightscoutDownloader.fetchData(from: endpoint, with: request, sessions: sessions, completion: completion)
    }

    private func fetchData(
        from endpoint: APIEndpoint,
        queryItems: [QueryItem],
        completion: @escaping (NightscoutResult<Data>) -> Void
    ) {
        guard let request = router.configureURLRequest(for: endpoint, queryItems: queryItems, httpMethod: .get) else {
            completion(.failure(.invalidURL))
            return
        }

        fetchData(from: endpoint, with: request, completion: completion)
    }

    private func fetch<Response: JSONParseable>(
        from endpoint: APIEndpoint,
        queryItems: [QueryItem] = [],
        completion: @escaping (NightscoutResult<Response>) -> Void
    ) {
        fetchData(from: endpoint, queryItems: queryItems) { result in
            switch result {
            case .success(let data):
                do {
                    guard let parsed = try Response.parse(fromData: data) else {
                        completion(.failure(.dataParsingFailure(data)))
                        return
                    }
                    completion(.success(parsed))
                } catch {
                    completion(.failure(.jsonParsingError(error)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}


//
//  Nightscout.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 2/16/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Foundation


/// The primary interface for interacting with the Nightscout API.
/// This class performs operations such as:
/// - fetching and uploading blood glucose entries
/// - fetching, uploading, updating, and deleting treatments
/// - fetching, uploading, updating, and deleting profile records
/// - fetching device statuses
/// - fetching the site status and settings
public final class Nightscout {
    /// The base URL for the Nightscout site.
    /// This is the URL the user would visit to view their Nightscout home page.
    public var baseURL: URL

    /// The API secret for the base URL.
    /// If this property is `nil`, upload, update, and delete operations will produce `NightscoutError.missingAPISecret`.
    public var apiSecret: String?

    /// The observers responding to operations performed by this `Nightscout` instance.
    private let _observers: ThreadSafe<[NightscoutObserver]>

    /// Initializes a Nightscout instance from the base URL and (optionally) the API secret.
    /// - Parameter baseURL: The base URL for the Nightscout site.
    /// - Parameter apiSecret: The API secret for the Nightscout site. Defaults to `nil`.
    /// - Returns: A Nightscout instance from the base URL and API secret.
    public init(baseURL: URL, apiSecret: String? = nil) {
        self.baseURL = baseURL
        self.apiSecret = apiSecret
        self._observers = ThreadSafe([])
    }

    /// Attempts to initialize a Nightscout instance from the base URL string and (optionally) the API secret.
    /// - Parameter baseURLString: The base URL string from which the base URL should attempt to be created.
    /// - Parameter apiSecret: The API secret for the Nightscout site. Defaults to `nil`.
    /// - Throws: `NightscoutError.invalidURL` if `baseURLString` cannot be used to create a valid URL.
    /// - Returns: A Nightscout instance from the base URL and API secret.
    public convenience init(baseURLString: String, apiSecret: String? = nil) throws {
        guard let baseURL = URL(string: baseURLString) else {
            throw NightscoutError.invalidURL
        }
        self.init(baseURL: baseURL, apiSecret: apiSecret)
    }
}

// MARK: - Observers

extension Nightscout {
    /// Returns an array containing the objects observing this `Nightscout` instance.
    ///
    /// This value is immutable.
    /// For adding observers, see `addObserver(_:)` and `addObservers(_:)`.
    /// For removing observers, see `removeObserver(_:)` and `removeAllObservers()`.
    public var observers: [NightscoutObserver] {
        return _observers.value
    }

    /// Adds the observer to this `Nightscout` instance.
    /// - Parameter observer: The object to begin observing this `Nightscout` instance.
    public func addObserver(_ observer: NightscoutObserver) {
        _observers.atomically { $0.append(observer) }
    }

    /// Adds the observers to this `Nightscout` instance.
    /// - Parameter observers: The objects to begin observing this `Nightscout` instance.
    public func addObservers(_ observers: [NightscoutObserver]) {
        _observers.atomically { $0.append(contentsOf: observers) }
    }

    /// Adds the observers to this `Nightscout` instance.
    /// - Parameter observers: The objects to begin observing this `Nightscout` instance.
    public func addObservers(_ observers: NightscoutObserver...) {
        addObservers(observers)
    }

    /// Removes the observer from this `Nightscout` instance.
    ///
    /// If the observer is not currently observing this `Nightscout` instance, this method does nothing.
    /// If the observer occurs multiple times in the list of observers, all instances of the observer will be removed.
    /// - Parameter observer: The object to stop observing this `Nightscout` instance.
    public func removeObserver(_ observer: NightscoutObserver) {
        _observers.atomically { observers in
            while let index = observers.index(where: { $0 === observer }) {
                observers.remove(at: index)
            }
        }
    }

    /// Removes all observers from this `Nightscout` instance.
    public func removeAllObservers() {
        _observers.atomically { $0.removeAll() }
    }
}

// MARK: - API

fileprivate enum HTTPMethod: String {
    case get = "GET"
    case put = "PUT"
    case post = "POST"
    case delete = "DELETE"
}

extension Nightscout {
    private enum APIEndpoint: String {
        case entries = "entries"
        case treatments = "treatments"
        case profiles = "profile"
        case status = "status"
        case deviceStatus = "devicestatus"
        case authorization = "experiments/test"
    }

    private enum QueryItem {
        case count(Int)
        case find(property: String, ComparativeOperator, value: String)

        enum ComparativeOperator: String {
            case lessThan = "lt"
            case lessThanOrEqualTo = "lte"
            case equalTo
            case greaterThanOrEqualTo = "gte"
            case greaterThan = "gt"
        }

        var urlQueryItem: URLQueryItem {
            switch self {
            case .count(let count):
                return URLQueryItem(name: "count", value: String(count))
            case .find(property: let property, let `operator`, value: let value):
                let operatorString = (`operator` == .equalTo) ? "" : "[$\(`operator`.rawValue)]"
                return URLQueryItem(name: "find[\(property)]\(operatorString)", value: value)
            }
        }

        static func entryDate(_ operator: ComparativeOperator, _ date: Date) -> QueryItem {
            let millisecondsSince1970 = Int(date.timeIntervalSince1970.milliseconds)
            return .find(property: NightscoutEntry.Key.millisecondsSince1970.key, `operator`, value: String(millisecondsSince1970))
        }

        static func entryDates(from dateInterval: DateInterval) -> [QueryItem] {
            return [.entryDate(.greaterThanOrEqualTo, dateInterval.start), .entryDate(.lessThanOrEqualTo, dateInterval.end)]
        }

        static func treatmentEventType(matching eventType: NightscoutTreatment.EventType) -> QueryItem {
            return .find(property: NightscoutTreatment.Key.eventTypeString.key, .equalTo, value: eventType.simpleRawValue)
        }

        static func treatmentDate(_ operator: ComparativeOperator, _ date: Date) -> QueryItem {
            let dateString = "\(TimeFormatter.string(from: date)).000Z"
            return .find(property: NightscoutTreatment.Key.dateString.key, `operator`, value: dateString)
        }

        static func treatmentDates(from dateInterval: DateInterval) -> [QueryItem] {
            return [.treatmentDate(.greaterThanOrEqualTo, dateInterval.start), .treatmentDate(.lessThanOrEqualTo, dateInterval.end)]
        }

        static func deviceStatusDate(_ operator: ComparativeOperator, _ date: Date) -> QueryItem {
            let dateString = "\(TimeFormatter.string(from: date))Z"
            return .find(property: NightscoutDeviceStatus.Key.dateString.key, `operator`, value: dateString)
        }

        static func deviceStatusDates(from dateInterval: DateInterval) -> [QueryItem] {
            return [.deviceStatusDate(.greaterThanOrEqualTo, dateInterval.start), .deviceStatusDate(.lessThanOrEqualTo, dateInterval.end)]
        }
    }

    private static let apiVersion = "v1"

    private func route(to endpoint: APIEndpoint, queryItems: [QueryItem] = []) -> URL? {
        let base = baseURL.appendingPathComponents("api", Nightscout.apiVersion, endpoint.rawValue)
        let urlQueryItems = queryItems.map { $0.urlQueryItem }
        return base.components?.addingQueryItems(urlQueryItems).url
    }

    private func urlSession(for endpoint: APIEndpoint) -> URLSession {
        switch endpoint {
        case .entries:
            return .entriesSession
        case .treatments:
            return .treatmentsSession
        case .profiles:
            return .profilesSession
        case .status:
            return .settingsSession
        case .deviceStatus:
            return .deviceStatusSession
        case .authorization:
            return .authorizationSession
        }
    }

    private func configureURLRequest(for endpoint: APIEndpoint, queryItems: [QueryItem] = [], httpMethod: HTTPMethod? = nil) -> URLRequest? {
        guard let url = route(to: endpoint, queryItems: queryItems) else {
            return nil
        }

        var request = URLRequest(url: url)
        var headers = [
            "Content-Type": "application/json",
            "Accept": "application/json",
        ]
        apiSecret.map { headers["api-secret"] = $0.sha1() }
        headers.forEach { header, value in request.setValue(value, forHTTPHeaderField: header) }
        request.httpMethod = httpMethod?.rawValue

        return request
    }
}

// MARK: - Fetching

extension Nightscout {
    /// Takes a snapshot of the current Nightscout site.
    /// - Parameter recentBloodGlucoseEntryCount: The number of recent blood glucose entries to fetch. Defaults to 10.
    /// - Parameter recentTreatmentCount: The number of recent treatments to fetch. Defaults to 10.
    /// - Parameter recentDeviceStatusCount: The number of recent device statuses to fetch. Defaults to 10.
    /// - Parameter completion: The completion handler to be called upon completing the operation.
    /// - Parameter result: The result of the operation.
    public func snapshot(recentBloodGlucoseEntryCount: Int = 10, recentTreatmentCount: Int = 10, recentDeviceStatusCount: Int = 10,
                         completion: @escaping (_ result: NightscoutResult<NightscoutSnapshot>) -> Void) {
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

        snapshotGroup.wait()

        // There's a race condition with errors here, but if any fetch request fails, we'll report an error--it doesn't matter which.
        guard error.value == nil else {
            completion(.failure(error.value!))
            return
        }

        let snapshot = NightscoutSnapshot(timestamp: timestamp, status: status!, entries: entries,
                                          treatments: treatments, profileRecords: profileRecords, deviceStatuses: deviceStatuses)
        completion(.success(snapshot))
    }

    /// Fetches the status of the Nightscout site.
    /// - Parameter completion: The completion handler to be called upon completing the operation.
    /// - Parameter result: The result of the operation.
    public func fetchStatus(completion: ((_ result: NightscoutResult<NightscoutStatus>) -> Void)? = nil) {
        fetch(from: .status) { (result: NightscoutResult<NightscoutStatus>) in
            self.observers.notify(
                for: result, from: self,
                ifSuccess: { observer in { nightscout, status in observer.nightscout(nightscout, didFetchStatus: status) } }
            )
            completion?(result)
        }
    }

    /// Fetches the most recent blood glucose entries.
    /// - Parameter count: The number of recent blood glucose entries to fetch. Defaults to 10.
    /// - Parameter completion: The completion handler to be called upon completing the operation.
    /// - Parameter result: The result of the operation.
    public func fetchMostRecentEntries(count: Int = 10,
                                       completion: ((_ result: NightscoutResult<[NightscoutEntry]>) -> Void)? = nil) {
        let queryItems: [QueryItem] = [.count(count)]
        fetchArray(from: .entries, queryItems: queryItems) { (result: NightscoutResult<[NightscoutEntry]>) in
            self.observers.notify(
                for: result, from: self,
                ifSuccess: { observer in { nightscout, entries in observer.nightscout(nightscout, didFetchEntries: entries) } }
            )
            completion?(result)
        }
    }

    /// Fetches the blood glucose entries from within the specified `DateInterval`.
    /// - Parameter interval: The interval from which blood glucose entries should be fetched.
    /// - Parameter maxCount: The maximum number of blood glucose entries to fetch. Defaults to `2 ** 31`, where `**` is exponentiation.
    /// - Parameter completion: The completion handler to be called upon completing the operation.
    /// - Parameter result: The result of the operation.
    public func fetchEntries(from interval: DateInterval, maxCount: Int = 2 << 31,
                             completion: ((_ result: NightscoutResult<[NightscoutEntry]>) -> Void)? = nil) {
        let queryItems = QueryItem.entryDates(from: interval).appending(.count(maxCount))
        fetchArray(from: .entries, queryItems: queryItems) { (result: NightscoutResult<[NightscoutEntry]>) in
            self.observers.notify(
                for: result, from: self,
                ifSuccess: { observer in { nightscout, entries in observer.nightscout(nightscout, didFetchEntries: entries) } }
            )
            completion?(result)
        }
    }

    /// Fetches the most recent treatments.
    /// - Parameter count: The number of recent treatments to fetch. Defaults to 10.
    /// - Parameter completion: The completion handler to be called upon completing the operation.
    /// - Parameter result: The result of the operation.
    public func fetchMostRecentTreatments(count: Int = 10,
                                          completion: ((_ result: NightscoutResult<[NightscoutTreatment]>) -> Void)? = nil) {
        let queryItems: [QueryItem] = [.count(count)]
        fetchArray(from: .treatments, queryItems: queryItems) { (result: NightscoutResult<[NightscoutTreatment]>) in
            self.observers.notify(
                for: result, from: self,
                ifSuccess: { observer in { nightscout, treatments in observer.nightscout(nightscout, didFetchTreatments: treatments) } }
            )
            completion?(result)
        }
    }

    /// Fetches the treatments from within the specified `DateInterval`.
    /// - Parameter interval: The interval from which treatments should be fetched.
    /// - Parameter maxCount: The maximum number of treatments to fetch. Defaults to `2 ** 31`, where `**` is exponentiation.
    /// - Parameter completion: The completion handler to be called upon completing the operation.
    /// - Parameter result: The result of the operation.
    public func fetchTreatments(from interval: DateInterval, maxCount: Int = 2 << 31,
                                completion: ((_ result: NightscoutResult<[NightscoutTreatment]>) -> Void)? = nil) {
        let queryItems = QueryItem.treatmentDates(from: interval).appending(.count(maxCount))
        fetchArray(from: .treatments, queryItems: queryItems) { (result: NightscoutResult<[NightscoutTreatment]>) in
            self.observers.notify(
                for: result, from: self,
                ifSuccess: { observer in { nightscout, treatments in observer.nightscout(nightscout, didFetchTreatments: treatments) } }
            )
            completion?(result)
        }
    }

    /// Fetches the profile records.
    /// - Parameter completion: The completion handler to be called upon completing the operation.
    /// - Parameter result: The result of the operation.
    public func fetchProfileRecords(completion: ((_ result: NightscoutResult<[NightscoutProfileRecord]>) -> Void)? = nil) {
        fetchArray(from: .profiles) { (result: NightscoutResult<[NightscoutProfileRecord]>) in
            self.observers.notify(
                for: result, from: self,
                ifSuccess: { observer in { nightscout, records in observer.nightscout(nightscout, didFetchProfileRecords: records) } }
            )
            completion?(result)
        }
    }

    /// Fetches the most recent device statuses.
    /// - Parameter count: The number of recent device statuses to fetch. Defaults to 10.
    /// - Parameter completion: The completion handler to be called upon completing the operation.
    /// - Parameter result: The result of the operation.
    public func fetchMostRecentDeviceStatuses(count: Int = 10,
                                              completion: ((_ result: NightscoutResult<[NightscoutDeviceStatus]>) -> Void)? = nil) {
        let queryItems: [QueryItem] = [.count(count)]
        fetchArray(from: .deviceStatus, queryItems: queryItems) { (result: NightscoutResult<[NightscoutDeviceStatus]>) in
            self.observers.notify(
                for: result, from: self,
                ifSuccess: { observer in { nightscout, deviceStatuses in observer.nightscout(nightscout, didFetchDeviceStatuses: deviceStatuses) } }
            )
            completion?(result)
        }
    }

    /// Fetches the device statuses from within the specified `DateInterval`.
    /// - Parameter interval: The interval from which device statuses should be fetched.
    /// - Parameter maxCount: The maximum number of device statuses to fetch. Defaults to `2 ** 31`, where `**` is exponentiation.
    /// - Parameter completion: The completion handler to be called upon completing the operation.
    /// - Parameter result: The result of the operation.
    public func fetchDeviceStatuses(from interval: DateInterval, maxCount: Int = 2 << 31,
                                    completion: ((_ result: NightscoutResult<[NightscoutDeviceStatus]>) -> Void)? = nil) {
        let queryItems = QueryItem.deviceStatusDates(from: interval) + [.count(maxCount)]
        fetchArray(from: .deviceStatus, queryItems: queryItems) { (result: NightscoutResult<[NightscoutDeviceStatus]>) in
            self.observers.notify(
                for: result, from: self,
                ifSuccess: { observer in { nightscout, deviceStatuses in observer.nightscout(nightscout, didFetchDeviceStatuses: deviceStatuses) } }
            )
            completion?(result)
        }
    }
}

extension Nightscout {
    private func fetchData(from endpoint: APIEndpoint, with request: URLRequest,
                           completion: @escaping (NightscoutResult<Data>) -> Void) {
        let session = urlSession(for: endpoint)
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

    private func fetchData(from endpoint: APIEndpoint, queryItems: [QueryItem],
                           completion: @escaping (NightscoutResult<Data>) -> Void) {
        guard let request = configureURLRequest(for: endpoint, queryItems: queryItems, httpMethod: .get) else {
            completion(.failure(.invalidURL))
            return
        }

        fetchData(from: endpoint, with: request, completion: completion)
    }

    private func fetch<Response: JSONParseable>(from endpoint: APIEndpoint, queryItems: [QueryItem] = [], completion: @escaping (NightscoutResult<Response>) -> Void) {
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

    // TODO: eliminate this method using conditional conformance with Array in Swift 4.1
    private func fetchArray<Response: JSONParseable>(from endpoint: APIEndpoint, queryItems: [QueryItem] = [],
                                                     completion: @escaping (NightscoutResult<[Response]>) -> Void) {
        fetchData(from: endpoint, queryItems: queryItems) { result in
            switch result {
            case .success(let data):
                do {
                    guard let parsed = try [Response].parse(fromData: data) else {
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

// MARK: - Uploading

extension Nightscout {
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

    /// Verifies that the instance is authorized to upload, update, and delete entities.
    /// - Parameter completion: The completion handler to be called upon completing the operation.
    /// - Parameter error: The error that occurred in verifying authorization. `nil` indicates success.
    public func verifyAuthorization(completion: ((_ error: NightscoutError?) -> Void)? = nil) {
        guard apiSecret != nil else {
            completion?(.missingAPISecret)
            return
        }

        guard let request = configureURLRequest(for: .authorization) else {
            completion?(.invalidURL)
            return
        }

        fetchData(from: .authorization, with: request) { result in
            self.observers.notify(
                for: result, from: self,
                ifSuccess: { observer in { nightscout, _ in observer.nightscoutDidVerifyAuthorization(nightscout) } }
            )
            completion?(result.error)
        }
    }

    /// Uploads the blood glucose entries.
    /// - Parameter entries: The blood glucose entries to upload.
    /// - Parameter completion: The completion handler to be called upon completing the operation.
    /// - Parameter result: The result of the operation. A successful result contains a tuple containing the successfully uploaded entries and the rejected entries.
    public func uploadEntries(_ entries: [NightscoutEntry],
                              completion: ((_ result: PostResponse<NightscoutEntry>) -> Void)? = nil) {
        post(entries, to: .entries) { (result: PostResponse<NightscoutEntry>) in
            self.observers.notify(
                for: result, from: self,
                withSuccesses: { observer in { nightscout, entries in observer.nightscout(nightscout, didUploadEntries: entries) } },
                withRejections: { observer in { nightscout, entries in observer.nightscout(nightscout, didFailToUploadEntries: entries) } }
            )
            completion?(result)
        }
    }

    // FIXME: entry deletion fails--but why?
    /* public */ func deleteEntries(_ entries: [NightscoutEntry],
                                    completion: @escaping (_ operationResult: OperationResult<NightscoutEntry>) -> Void) {
        // TODO: observer API once this is fixed
        delete(entries, from: .entries, completion: completion)
    }

    /// Uploads the treatments.
    /// - Parameter treatments: The treatments to upload.
    /// - Parameter completion: The completion handler to be called upon completing the operation.
    /// - Parameter result: The result of the operation. A successful result contains a tuple containing the successfully uploaded treatments and the rejected treatments.
    public func uploadTreatments(_ treatments: [NightscoutTreatment],
                                 completion: ((_ result: PostResponse<NightscoutTreatment>) -> Void)? = nil) {
        post(treatments, to: .treatments) { (result: PostResponse<NightscoutTreatment>) in
            self.observers.notify(
                for: result, from: self,
                withSuccesses: { observer in { nightscout, treatments in observer.nightscout(nightscout, didUploadTreatments: treatments) } },
                withRejections: { observer in { nightscout, treatments in observer.nightscout(nightscout, didFailToUploadTreatments: treatments) } }
            )
            completion?(result)
        }
    }

    /// Updates the treatments.
    /// If treatment dates are modified, Nightscout will post the treatments as duplicates. In these cases, it is recommended to delete these treatments
    /// and reupload them rather than update them.
    /// - Parameter treatments: The treatments to update.
    /// - Parameter completion: The completion handler to be called upon completing the operation.
    /// - Parameter operationResult: The result of the operation, which contains both the successfully updated treatments and the rejections.
    public func updateTreatments(_ treatments: [NightscoutTreatment],
                                 completion: ((_ operationResult: OperationResult<NightscoutTreatment>) -> Void)? = nil) {
        put(treatments, to: .treatments) { (operationResult: OperationResult<NightscoutTreatment>) in
            self.observers.notify(
                for: operationResult, from: self,
                withSuccesses: { observer in { nightscout, treatments in observer.nightscout(nightscout, didUpdateTreatments: treatments) } },
                withRejections: { observer in { nightscout, treatments in observer.nightscout(nightscout, didFailToUpdateTreatments: treatments) } }
            )
            completion?(operationResult)
        }
    }

    /// Deletes the treatments.
    /// - Parameter treatments: The treatments to delete.
    /// - Parameter completion: The completion handler to be called upon completing the operation.
    /// - Parameter operationResult: The result of the operation, which contains both the successfully deleted treatments and the rejections.
    public func deleteTreatments(_ treatments: [NightscoutTreatment],
                                 completion: ((_ operationResult: OperationResult<NightscoutTreatment>) -> Void)? = nil) {
        delete(treatments, from: .treatments) { (operationResult: OperationResult<NightscoutTreatment>) in
            self.observers.notify(
                for: operationResult, from: self,
                withSuccesses: { observer in { nightscout, treatments in observer.nightscout(nightscout, didDeleteTreatments: treatments) } },
                withRejections: { observer in { nightscout, treatments in observer.nightscout(nightscout, didFailToDeleteTreatments: treatments) } }
            )
            completion?(operationResult)
        }
    }

    /// Uploads the profile records.
    /// - Parameter records: The profile records to upload.
    /// - Parameter completion: The completion handler to be called upon completing the operation.
    /// - Parameter result: The result of the operation. A successful result contains a tuple containing the successfully uploaded records and the rejected records.
    public func uploadProfileRecords(_ records: [NightscoutProfileRecord],
                                     completion: ((_ result: PostResponse<NightscoutProfileRecord>) -> Void)? = nil) {
        post(records, to: .profiles) { (result: PostResponse<NightscoutProfileRecord>) in
            self.observers.notify(
                for: result, from: self,
                withSuccesses: { observer in { nightscout, records in observer.nightscout(nightscout, didUploadProfileRecords: records) } },
                withRejections: { observer in { nightscout, records in observer.nightscout(nightscout, didFailToUploadProfileRecords: records) } }
            )
            completion?(result)
        }
    }

    /// Updates the profile records.
    /// If profile record dates are modified, Nightscout will post the profile records as duplicates. In these cases, it is recommended to delete these records
    /// and reupload them rather than update them.
    /// - Parameter records: The profile records to update.
    /// - Parameter completion: The completion handler to be called upon completing the operation.
    /// - Parameter operationResult: The result of the operation, which contains both the successfully updated records and the rejections.
    public func updateProfileRecords(_ records: [NightscoutProfileRecord],
                                     completion: ((_ operationResult: OperationResult<NightscoutProfileRecord>) -> Void)? = nil) {
        put(records, to: .profiles) { (operationResult: OperationResult<NightscoutProfileRecord>) in
            self.observers.notify(
                for: operationResult, from: self,
                withSuccesses: { observer in { nightscout, records in observer.nightscout(nightscout, didUpdateProfileRecords: records) } },
                withRejections: { observer in { nightscout, records in observer.nightscout(nightscout, didFailToUpdateProfileRecords: records) } }
            )
            completion?(operationResult)
        }
    }

    /// Deletes the profile records.
    /// - Parameter records: The profile records to delete.
    /// - Parameter completion: The completion handler to be called upon completing the operation.
    /// - Parameter operationResult: The result of the operation, which contains both the successfully deleted records and the rejections.
    public func deleteProfileRecords(_ records: [NightscoutProfileRecord],
                                     completion: ((_ operationResult: OperationResult<NightscoutProfileRecord>) -> Void)? = nil) {
        delete(records, from: .profiles) { (operationResult: OperationResult<NightscoutProfileRecord>) in
            self.observers.notify(
                for: operationResult, from: self,
                withSuccesses: { observer in { nightscout, records in observer.nightscout(nightscout, didDeleteProfileRecords: records) } },
                withRejections: { observer in { nightscout, records in observer.nightscout(nightscout, didFailToDeleteProfileRecords: records) } }
            )
            completion?(operationResult)
        }
    }
}

extension Nightscout {
    private func uploadData(_ data: Data, to endpoint: APIEndpoint, with request: URLRequest,
                            completion: @escaping (NightscoutResult<Data>) -> Void) {
        let session = urlSession(for: endpoint)
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

    private func upload<Payload: JSONConvertible, Response: JSONParseable>(_ item: Payload, to endpoint: APIEndpoint, httpMethod: HTTPMethod,
                                                                           completion: @escaping (NightscoutResult<Response>) -> Void) {
        guard apiSecret != nil else {
            completion(.failure(.missingAPISecret))
            return
        }

        guard let request = configureURLRequest(for: endpoint, httpMethod: httpMethod) else {
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

    // TODO: Remove this with conditional conformance in Swift 4.1
    private func uploadArray<Payload: JSONRepresentable, Response: JSONParseable>(_ items: [Payload], to endpoint: APIEndpoint, httpMethod: HTTPMethod,
                                                                                  completion: @escaping (NightscoutResult<[Response]>) -> Void) {
        guard apiSecret != nil else {
            completion(.failure(.missingAPISecret))
            return
        }

        guard let request = configureURLRequest(for: endpoint, httpMethod: httpMethod) else {
            completion(.failure(.invalidURL))
            return
        }

        let data: Data
        do {
            data = try items.data()
        } catch {
            completion(.failure(.jsonParsingError(error)))
            return
        }

        uploadData(data, to: endpoint, with: request) { result in
            switch result {
            case .success(let data):
                do {
                    guard let response = try [Response].parse(fromData: data) else {
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

    private func post<Payload: JSONConvertible>(_ items: [Payload], to endpoint: APIEndpoint,
                                                completion: @escaping (PostResponse<Payload>) -> Void) {
        uploadArray(items, to: endpoint, httpMethod: .post) { (result: NightscoutResult<[Payload]>) in
            switch result {
            case .success(let uploadedItems):
                let uploadedItems = Set(uploadedItems)
                let rejectedItems = Set(items).subtracting(uploadedItems)
                completion(.success((uploadedItems: uploadedItems, rejectedItems: rejectedItems)))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func put<Payload: JSONConvertible>(_ items: [Payload], to endpoint: APIEndpoint,
                                               completion: @escaping (OperationResult<Payload>) -> Void) {
        concurrentPerform(_put, items: items, endpoint: endpoint, completion: completion)
    }

    private func _put<Payload: JSONConvertible>(_ item: Payload, to endpoint: APIEndpoint,
                                                completion: @escaping (NightscoutError?) -> Void) {
        upload(item, to: endpoint, httpMethod: .put) { (result: NightscoutResult<AnyJSON>) in
            completion(result.error)
        }
    }

    private func delete<Payload: UniquelyIdentifiable>(_ items: [Payload], from endpoint: APIEndpoint,
                                                       completion: @escaping (OperationResult<Payload>) -> Void) {
        concurrentPerform(_delete, items: items, endpoint: endpoint, completion: completion)
    }

    private func _delete<Payload: UniquelyIdentifiable>(_ item: Payload, from endpoint: APIEndpoint,
                                                        completion: @escaping (NightscoutError?) -> Void) {
        guard apiSecret != nil else {
            completion(.missingAPISecret)
            return
        }

        guard var request = configureURLRequest(for: endpoint, httpMethod: .delete) else {
            completion(.invalidURL)
            return
        }

        request.url?.appendPathComponent(item.id)
        fetchData(from: endpoint, with: request) { result in
            completion(result.error)
        }
    }

    private typealias Operation<T> = (_ item: T, _ endpoint: APIEndpoint, _ completion: @escaping (NightscoutError?) -> Void) -> Void
    private func concurrentPerform<T>(_ operation: Operation<T>, items: [T], endpoint: APIEndpoint,
                                      completion: @escaping (OperationResult<T>) -> Void) {
        let rejections: ThreadSafe<Set<Rejection<T>>> = ThreadSafe([])
        let operationGroup = DispatchGroup()

        for item in items {
            operationGroup.enter()
            operation(item, endpoint) { error in
                error.map { error in
                    rejections.atomically { rejections in
                        let rejection = Rejection(item: item, error: error)
                        rejections.insert(rejection)
                    }
                }
                operationGroup.leave()
            }
        }

        operationGroup.wait()

        let rejectionsSet = rejections.value
        let processedSet = Set(items).subtracting(rejectionsSet.map { $0.item })
        let operationResult: OperationResult = (processedItems: processedSet, rejections: rejectionsSet)
        completion(operationResult)
    }
}

fileprivate extension URLSession {
    static let settingsSession = URLSession(configuration: .default)
    static let entriesSession = URLSession(configuration: .default)
    static let treatmentsSession = URLSession(configuration: .default)
    static let profilesSession = URLSession(configuration: .default)
    static let deviceStatusSession = URLSession(configuration: .default)
    static let authorizationSession = URLSession(configuration: .default)
}

//
//  Nightscout.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 2/16/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Foundation


/// Describes an error occurring in communication with a Nightscout site.
public enum NightscoutError: Error {
    /// An error that occurs when the Nightscout URL is invalid.
    case invalidURL

    /// An error that occurs when attempting to upload, update, or delete Nightscout entities without providing the API secret.
    case missingAPISecret

    /// An error that occurs when fetching Nightscout data.
    /// The associated value contains the error from the call to `URLSession.dataTask`.
    case fetchError(Error)

    /// An error that occurs when uploading Nightscout data.
    /// The associated value contains the error from the call to `URLSession.dataTask` or `URLSession.uploadTask`.
    case uploadError(Error)

    /// An error that occurs when the `URLResponse` received is not an `HTTPURLResponse`.
    case notAnHTTPURLResponse

    /// An error that occurs when a response is received, but the data is absent.
    case missingData

    /// An error that occurs when the HTTP status code 401 is returned.
    /// If this error results from an attempt to upload, modify, or delete a Nightscout entity, a possible cause is an invalid API secret.
    case unauthorized

    /// An error that occurs when an unexpected HTTP response is returned.
    /// The associated value contains the HTTP status code and the body of the message response.
    case httpError(statusCode: Int, body: String)

    /// An error that occurs when the received data cannot be parsed as JSON.
    /// The associated value contains the error from the call to `JSONSerialization.jsonObject(with:options:)`.
    case jsonParsingError(Error)

    /// An error that occurs when the received data can be parsed as JSON but does not match the expected format of a Nightscout entity.
    /// The associated value contains the data which could not be parsed.
    case dataParsingFailure(Data)
}

/// The primary interface for interacting with the Nightscout API.
/// This class performs operations such as:
/// - fetching and uploading blood glucose entries
/// - fetching, uploading, updating, and deleting treatments
/// - fetching, uploading, updating, and deleting profile records
/// - fetching device statuses
/// - fetching the server status and settings
public class Nightscout {
    /// The base URL for the Nightscout site.
    /// This is the URL the user would visit to view their Nightscout home page.
    public var baseURL: URL

    /// The API secret for the base URL.
    /// If this property is `nil`, only fetch operations can be performed.
    public var apiSecret: String?

    /// Initializes a Nightscout instance from the base URL and (optionally) the API secret.
    /// - Parameter baseURL: The base URL for the Nightscout site.
    /// - Parameter apiSecret: The API secret for the Nightscout site. Defaults to `nil`.
    /// - Returns: A Nightscout instance from the base URL and API secret.
    public init(baseURL: URL, apiSecret: String? = nil) {
        self.baseURL = baseURL
        self.apiSecret = apiSecret
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

        if let apiSecret = apiSecret {
            headers["api-secret"] = apiSecret.sha1()
        }

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
    public func snapshot(recentBloodGlucoseEntryCount: Int = 10, recentTreatmentCount: Int = 10, recentDeviceStatusCount: Int = 10, completion: @escaping (_ result: NightscoutResult<NightscoutSnapshot>) -> Void) {
        let timestamp = Date()
        var status: NightscoutStatus?
        var deviceStatuses: [NightscoutDeviceStatus] = []
        var entries: [NightscoutEntry] = []
        var treatments: [NightscoutTreatment] = []
        var profileRecords: [NightscoutProfileRecord] = []
        var error: Error?

        let snapshotGroup = DispatchGroup()

        snapshotGroup.enter()
        fetchStatus { result in
            switch result {
            case .success(let fetchedStatus):
                status = fetchedStatus
            case .failure(let err):
                error = err
            }

            snapshotGroup.leave()
        }

        snapshotGroup.enter()
        fetchMostRecentDeviceStatuses(count: recentDeviceStatusCount) { result in
            switch result {
            case .success(let fetchedDeviceStatuses):
                deviceStatuses = fetchedDeviceStatuses
            case .failure(let err):
                error = err
            }
            snapshotGroup.leave()
        }

        snapshotGroup.enter()
        fetchProfileRecords { result in
            switch result {
            case .success(let fetchedProfileRecords):
                profileRecords = fetchedProfileRecords
            case .failure(let err):
                error = err
            }

            snapshotGroup.leave()
        }

        snapshotGroup.enter()
        fetchMostRecentEntries(count: recentBloodGlucoseEntryCount) { result in
            switch result {
            case .success(let fetchedBloodGlucoseEntries):
                entries = fetchedBloodGlucoseEntries
            case .failure(let err):
                error = err
            }

            snapshotGroup.leave()
        }

        snapshotGroup.enter()
        fetchMostRecentTreatments(count: recentTreatmentCount) { result in
            switch result {
            case .success(let fetchedTreatments):
                treatments = fetchedTreatments
            case .failure(let err):
                error = err
            }

            snapshotGroup.leave()
        }

        snapshotGroup.wait()

        // There's a race condition with errors here, but if any fetch request fails, we'll report an error--it doesn't matter which.
        guard error == nil else {
            completion(.failure(.fetchError(error!)))
            return
        }

        let snapshot = NightscoutSnapshot(timestamp: timestamp, status: status!, entries: entries, treatments: treatments, profileRecords: profileRecords, deviceStatuses: deviceStatuses)
        completion(.success(snapshot))
    }

    /// Fetches the status of the Nightscout site.
    /// - Parameter completion: The completion handler to be called upon completing the operation.
    /// - Parameter result: The result of the operation.
    public func fetchStatus(completion: @escaping (_ result: NightscoutResult<NightscoutStatus>) -> Void) {
        fetch(from: .status, completion: completion)
    }

    /// Fetches the most recent blood glucose entries.
    /// - Parameter count: The number of recent blood glucose entries to fetch. Defaults to 10.
    /// - Parameter completion: The completion handler to be called upon completing the operation.
    /// - Parameter result: The result of the operation.
    public func fetchMostRecentEntries(count: Int = 10, completion: @escaping (_ result: NightscoutResult<[NightscoutEntry]>) -> Void) {
        let queryItems: [QueryItem] = [.count(count)]
        fetchArray(from: .entries, queryItems: queryItems, completion: completion)
    }

    /// Fetches the blood glucose entries from within the specified `DateInterval`.
    /// - Parameter interval: The interval from which blood glucose entries should be fetched.
    /// - Parameter maxCount: The maximum number of blood glucose entries to fetch. Defaults to `2 ** 31`, where `**` is exponentiation.
    /// - Parameter completion: The completion handler to be called upon completing the operation.
    /// - Parameter result: The result of the operation.
    public func fetchEntries(from interval: DateInterval, maxCount: Int = 2 << 31, completion: @escaping (_ result: NightscoutResult<[NightscoutEntry]>) -> Void) {
        let queryItems = QueryItem.entryDates(from: interval) + [.count(maxCount)]
        fetchArray(from: .entries, queryItems: queryItems, completion: completion)
    }

    /// Fetches the most recent treatments.
    /// - Parameter count: The number of recent treatments to fetch. Defaults to 10.
    /// - Parameter completion: The completion handler to be called upon completing the operation.
    /// - Parameter result: The result of the operation.
    public func fetchMostRecentTreatments(count: Int = 10, completion: @escaping (_ result: NightscoutResult<[NightscoutTreatment]>) -> Void) {
        let queryItems: [QueryItem] = [.count(count)]
        fetchArray(from: .treatments, queryItems: queryItems, completion: completion)
    }

    /// Fetches the treatments from within the specified `DateInterval`.
    /// - Parameter interval: The interval from which treatments should be fetched.
    /// - Parameter maxCount: The maximum number of treatments to fetch. Defaults to `2 ** 31`, where `**` is exponentiation.
    /// - Parameter completion: The completion handler to be called upon completing the operation.
    /// - Parameter result: The result of the operation.
    public func fetchTreatments(from interval: DateInterval, maxCount: Int = 2 << 31, completion: @escaping (_ result: NightscoutResult<[NightscoutTreatment]>) -> Void) {
        let queryItems = QueryItem.treatmentDates(from: interval) + [.count(maxCount)]
        fetchArray(from: .treatments, queryItems: queryItems, completion: completion)
    }

    // TODO: profile records by count / date if there are a large number of profiles?

    /// Fetches the profile records.
    /// - Parameter completion: The completion handler to be called upon completing the operation.
    /// - Parameter result: The result of the operation.
    public func fetchProfileRecords(completion: @escaping (_ result: NightscoutResult<[NightscoutProfileRecord]>) -> Void) {
        fetchArray(from: .profiles, completion: completion)
    }

    /// Fetches the most recent device statuses.
    /// - Parameter count: The number of recent device statuses to fetch. Defaults to 10.
    /// - Parameter completion: The completion handler to be called upon completing the operation.
    /// - Parameter result: The result of the operation.
    public func fetchMostRecentDeviceStatuses(count: Int = 10, completion: @escaping (_ result: NightscoutResult<[NightscoutDeviceStatus]>) -> Void) {
        let queryItems: [QueryItem] = [.count(count)]
        fetchArray(from: .deviceStatus, queryItems: queryItems, completion: completion)
    }

    /// Fetches the device statuses from within the specified `DateInterval`.
    /// - Parameter interval: The interval from which device statuses should be fetched.
    /// - Parameter maxCount: The maximum number of device statuses to fetch. Defaults to `2 ** 31`, where `**` is exponentiation.
    /// - Parameter completion: The completion handler to be called upon completing the operation.
    /// - Parameter result: The result of the operation.
    public func fetchDeviceStatuses(from interval: DateInterval, maxCount: Int = 2 << 31, completion: @escaping (_ result: NightscoutResult<[NightscoutDeviceStatus]>) -> Void) {
        let queryItems = QueryItem.deviceStatusDates(from: interval) + [.count(maxCount)]
        fetchArray(from: .deviceStatus, queryItems: queryItems, completion: completion)
    }
}

extension Nightscout {
    private func fetchData(from endpoint: APIEndpoint, with request: URLRequest, completion: @escaping (NightscoutResult<Data>) -> Void) {
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
                completion(.failure(.missingData))
                return
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

    private func fetchData(from endpoint: APIEndpoint, queryItems: [QueryItem], completion: @escaping (NightscoutResult<Data>) -> Void) {
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
    private func fetchArray<Response: JSONParseable>(from endpoint: APIEndpoint, queryItems: [QueryItem] = [], completion: @escaping (NightscoutResult<[Response]>) -> Void) {
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
    /// Verifies that the instance is authorized to upload, update, and delete entities.
    /// - Parameter completion: The completion handler to be called upon completing the operation.
    /// - Parameter error: The error that occurred in verifying authorization. `nil` indicates success.
    public func verifyAuthorization(completion: @escaping (_ error: NightscoutError?) -> Void) {
        guard apiSecret != nil else {
            completion(.missingAPISecret)
            return
        }

        guard let request = configureURLRequest(for: .authorization) else {
            completion(.invalidURL)
            return
        }

        fetchData(from: .authorization, with: request) { result in
            completion(result.error)
        }
    }

    /// Uploads the blood glucose entries.
    /// - Parameter entries: The blood glucose entries to upload.
    /// - Parameter completion: The completion handler to be called upon completing the operation.
    /// - Parameter result: The result of the operation. A successful result contains any entries that were rejected (i.e. not uploaded successfully).
    public func uploadEntries(_ entries: [NightscoutEntry], completion: @escaping (_ result: NightscoutResult<[NightscoutEntry]>) -> Void) {
        post(entries, to: .entries, completion: completion)
    }

    // FIXME: entry deletion fails--but why?
    /* public */ func deleteEntries(_ entries: [NightscoutEntry], completion: @escaping (_ failures: [(NightscoutEntry, NightscoutError)]) -> Void) {
        delete(entries, from: .entries, completion: completion)
    }

    /// Uploads the treatments.
    /// - Parameter treatments: The treatments to upload.
    /// - Parameter completion: The completion handler to be called upon completing the operation.
    /// - Parameter result: The result of the operation. A successful result contains any treatments that were rejected (i.e. not uploaded successfully).
    public func uploadTreatments(_ treatments: [NightscoutTreatment], completion: @escaping (_ result: NightscoutResult<[NightscoutTreatment]>) -> Void) {
        post(treatments, to: .treatments, completion: completion)
    }

    /// Updates the treatments.
    /// If treatment dates are modified, Nightscout will post the treatments as duplicates. In these cases, it is recommended to delete these treatments
    /// and reupload them rather than update them.
    /// - Parameter treatments: The treatments to update.
    /// - Parameter completion: The completion handler to be called upon completing the operation.
    /// - Parameter failures: An array of (treatment, error) tuples consisting of the treatments that failed to be updated and the causes of these failures.
    public func updateTreatments(_ treatments: [NightscoutTreatment], completion: @escaping (_ failures: [(NightscoutTreatment, NightscoutError)]) -> Void) {
        put(treatments, to: .treatments, completion: completion)
    }

    /// Deletes the treatments.
    /// - Parameter treatments: The treatments to delete.
    /// - Parameter completion: The completion handler to be called upon completing the operation.
    /// - Parameter failures: An array of (treatment, error) tuples consisting of the treatments that failed to be deleted and the causes of these failures.
    public func deleteTreatments(_ treatments: [NightscoutTreatment], completion: @escaping (_ failures: [(NightscoutTreatment, NightscoutError)]) -> Void) {
        delete(treatments, from: .treatments, completion: completion)
    }

    /// Uploads the profile records.
    /// - Parameter records: The profile records to upload.
    /// - Parameter completion: The completion handler to be called upon completing the operation.
    /// - Parameter result: The result of the operation. A successful result contains any profile records that were rejected (i.e. not uploaded successfully).
    public func uploadProfileRecords(_ records: [NightscoutProfileRecord], completion: @escaping (NightscoutResult<[NightscoutProfileRecord]>) -> Void) {
        post(records, to: .profiles, completion: completion)
    }

    /// Updates the profile records.
    /// If profile record dates are modified, Nightscout will post the profile records as duplicates. In these cases, it is recommended to delete these records
    /// and reupload them rather than update them.
    /// - Parameter records: The profile records to update.
    /// - Parameter completion: The completion handler to be called upon completing the operation.
    /// - Parameter failures: An array of (profile record, error) tuples consisting of the profile records that failed to be updated and the causes of these failures.
    public func updateProfileRecords(_ records: [NightscoutProfileRecord], completion: @escaping (_ failures: [(NightscoutProfileRecord, NightscoutError)]) -> Void) {
        put(records, to: .profiles, completion: completion)
    }

    /// Deletes the profile records.
    /// - Parameter records: The profile records to delete.
    /// - Parameter completion: The completion handler to be called upon completing the operation.
    /// - Parameter failures: An array of (profile record, error) tuples consisting of the profile records that failed to be deleted and the causes of these failures.
    public func deleteProfileRecords(_ records: [NightscoutProfileRecord], completion: @escaping (_ failures: [(NightscoutProfileRecord, NightscoutError)]) -> Void) {
        delete(records, from: .profiles, completion: completion)
    }
}

extension Nightscout {
    private func uploadData(_ data: Data, to endpoint: APIEndpoint, with request: URLRequest, completion: @escaping (NightscoutResult<Data>) -> Void) {
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
                completion(.failure(.missingData))
                return
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

    private func upload<Payload: JSONConvertible, Response: JSONParseable>(_ item: Payload, to endpoint: APIEndpoint, httpMethod: HTTPMethod, completion: @escaping (NightscoutResult<Response>) -> Void) {
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
    private func uploadArray<Payload: JSONRepresentable, Response: JSONParseable>(_ items: [Payload], to endpoint: APIEndpoint, httpMethod: HTTPMethod, completion: @escaping (NightscoutResult<[Response]>) -> Void) {
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

    private func post<Payload: JSONConvertible & Equatable>(_ items: [Payload], to endpoint: APIEndpoint, completion: @escaping (NightscoutResult<[Payload]>) -> Void) {
        uploadArray(items, to: endpoint, httpMethod: .post) { (result: NightscoutResult<[Payload]>) in
            switch result {
            case .success(let successfullyUploadedItems):
                let unsuccessfullyUploadedItems = items.filter { !successfullyUploadedItems.contains($0) }
                completion(.success(unsuccessfullyUploadedItems))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func put<Payload: JSONConvertible>(_ items: [Payload], to endpoint: APIEndpoint, completion: @escaping ([(Payload, NightscoutError)]) -> Void) {
        synchronizeOperation(_put, items: items, endpoint: endpoint, completion: completion)
    }

    private func _put<Payload: JSONConvertible>(_ item: Payload, to endpoint: APIEndpoint, completion: @escaping (NightscoutError?) -> Void) {
        upload(item, to: endpoint, httpMethod: .put) { (result: NightscoutResult<AnyJSON>) in
            completion(result.error)
        }
    }

    private func delete<Payload: UniquelyIdentifiable>(_ items: [Payload], from endpoint: APIEndpoint, completion: @escaping ([(Payload, NightscoutError)]) -> Void) {
        synchronizeOperation(_delete, items: items, endpoint: endpoint, completion: completion)
    }

    private func _delete<Payload: UniquelyIdentifiable>(_ item: Payload, from endpoint: APIEndpoint, completion: @escaping (NightscoutError?) -> Void) {
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
    private func synchronizeOperation<T>(_ operation: Operation<T>, items: [T], endpoint: APIEndpoint, completion: @escaping ([(T, NightscoutError)]) -> Void) {
        let dispatchGroup = DispatchGroup()
        let failuresModificationQueue = DispatchQueue(label: "nightscoutkit://synchronizeoperation")
        var failures: [(T, NightscoutError)?] = Array(repeating: nil, count: items.count)

        for (index, item) in items.enumerated() {
            dispatchGroup.enter()
            operation(item, endpoint) { error in
                if let error = error {
                    failuresModificationQueue.sync {
                        failures[index] = (item, error)
                    }
                }
                dispatchGroup.leave()
            }
        }

        dispatchGroup.wait()
        completion(failures.flatMap { $0 })
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

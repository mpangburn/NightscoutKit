//
//  Nightscout.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 2/16/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Foundation


public enum NightscoutError: Error {
    case invalidURL
    case missingAPISecret
    case fetchError(Error)
    case uploadError(Error)
    case invalidResponse(reason: String)
    case unauthorized
    case httpError(statusCode: Int, body: String)
    case dataParsingFailure(Data)
    case jsonParsingError(Error)
}

public enum NightscoutResult<T> {
    case success(T)
    case failure(NightscoutError)

    var error: NightscoutError? {
        switch self {
        case .success(_):
            return nil
        case .failure(let error):
            return error
        }
    }
}

public class Nightscout {
    public var baseURL: URL
    public var apiSecret: String?

    public init(baseURL: URL, apiSecret: String? = nil) {
        self.baseURL = baseURL
        self.apiSecret = apiSecret
    }

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
            let millisecondsSince1970 = date.timeIntervalSince1970.milliseconds
            return .find(property: BloodGlucoseEntry.Key.millisecondsSince1970, `operator`, value: String(millisecondsSince1970))
        }

        static func entryDates(from dateInterval: DateInterval) -> [QueryItem] {
            return [.entryDate(.greaterThanOrEqualTo, dateInterval.start), .entryDate(.lessThanOrEqualTo, dateInterval.end)]
        }

        static func treatmentEventType(matching eventType: Treatment.EventType) -> QueryItem {
            return .find(property: Treatment.Key.eventType, .equalTo, value: eventType.simpleRawValue)
        }

        static func treatmentDate(_ operator: ComparativeOperator, _ date: Date) -> QueryItem {
            let dateString = "\(TimeFormatter.string(from: date)).000Z"
            return .find(property: Treatment.Key.dateString, `operator`, value: dateString)
        }

        static func treatmentDates(from dateInterval: DateInterval) -> [QueryItem] {
            return [.treatmentDate(.greaterThanOrEqualTo, dateInterval.start), .treatmentDate(.lessThanOrEqualTo, dateInterval.end)]
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

    private func configureURLRequest(forEndpoint endpoint: APIEndpoint, queryItems: [QueryItem] = [], httpMethod: HTTPMethod? = nil) -> URLRequest? {
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
    public func snapshot(recentBloodGlucoseEntryCount: Int = 10, recentTreatmentCount: Int = 10, completion: @escaping (NightscoutResult<NightscoutSnapshot>) -> Void) {
        let date = Date()
        var settings = NightscoutSettings.default
        var bloodGlucoseEntries: [BloodGlucoseEntry] = []
        var treatments: [Treatment] = []
        var profileRecords: [ProfileRecord] = []
        var error: Error?

        let snapshotGroup = DispatchGroup()

        snapshotGroup.enter()
        fetchSettings { result in
            switch result {
            case .success(let fetchedSettings):
                settings = fetchedSettings
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
                bloodGlucoseEntries = fetchedBloodGlucoseEntries
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
        if let error = error {
            completion(.failure(.fetchError(error)))
        } else {
            let snapshot = NightscoutSnapshot(date: date, settings: settings, bloodGlucoseEntries: bloodGlucoseEntries, treatments: treatments, profileRecords: profileRecords)
            completion(.success(snapshot))
        }
    }

    public func fetchSettings(completion: @escaping (NightscoutResult<NightscoutSettings>) -> Void) {
        fetch(from: .status, completion: completion)
    }

    public func fetchMostRecentEntries(count: Int = 10, completion: @escaping (NightscoutResult<[BloodGlucoseEntry]>) -> Void) {
        let queryItems: [QueryItem] = [.count(count)]
        fetchArray(from: .entries, queryItems: queryItems, completion: completion)
    }

    public func fetchEntries(from interval: DateInterval, maxCount: Int = .max, completion: @escaping (NightscoutResult<[BloodGlucoseEntry]>) -> Void) {
        let queryItems = QueryItem.entryDates(from: interval) + [.count(maxCount)]
        fetchArray(from: .entries, queryItems: queryItems, completion: completion)
    }

    public func fetchMostRecentTreatments(count: Int = 10, completion: @escaping (NightscoutResult<[Treatment]>) -> Void) {
        let queryItems: [QueryItem] = [.count(count)]
        fetchArray(from: .treatments, queryItems: queryItems, completion: completion)
    }

    public func fetchTreatments(from interval: DateInterval, maxCount: Int = .max, completion: @escaping (NightscoutResult<[Treatment]>) -> Void) {
        let queryItems = QueryItem.treatmentDates(from: interval) + [.count(maxCount)]
        fetchArray(from: .treatments, queryItems: queryItems, completion: completion)
    }

    public func fetchProfileRecords(completion: @escaping (NightscoutResult<[ProfileRecord]>) -> Void) {
        fetchArray(from: .profiles, completion: completion)
    }
}

extension Nightscout {
    private func fetchData(from endpoint: APIEndpoint, with request: URLRequest, completion: @escaping (NightscoutResult<Data>) -> Void) {
        let session = urlSession(for: endpoint)
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.fetchError(error)))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.invalidResponse(reason: "Response received was not an HTTP response")))
                return
            }

            guard let data = data else {
                completion(.failure(.invalidResponse(reason: "Response contained no data")))
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
        guard let request = configureURLRequest(forEndpoint: endpoint, queryItems: queryItems, httpMethod: .get) else {
            completion(.failure(.invalidURL))
            return
        }

        fetchData(from: endpoint, with: request, completion: completion)
    }

    private func fetch<T: JSONParseable>(from endpoint: APIEndpoint, queryItems: [QueryItem] = [], completion: @escaping (NightscoutResult<T>) -> Void) {
        fetchData(from: endpoint, queryItems: queryItems) { result in
            switch result {
            case .success(let data):
                do {
                    guard let parsed = try T.parse(from: data) else {
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
    private func fetchArray<T: JSONParseable>(from endpoint: APIEndpoint, queryItems: [QueryItem] = [], completion: @escaping (NightscoutResult<[T]>) -> Void) {
        fetchData(from: endpoint, queryItems: queryItems) { result in
            switch result {
            case .success(let data):
                do {
                    guard let parsed = try [T].parse(from: data) else {
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
    public func verifyAuthorization(completion: @escaping (NightscoutError?) -> Void) {
        guard apiSecret != nil else {
            completion(.missingAPISecret)
            return
        }

        guard let request = configureURLRequest(forEndpoint: .authorization) else {
            completion(.invalidURL)
            return
        }

        fetchData(from: .authorization, with: request) { result in
            completion(result.error)
        }
    }

    public func uploadEntries(_ entries: [BloodGlucoseEntry], completion: @escaping (NightscoutResult<[BloodGlucoseEntry]>) -> Void) {
        post(entries, to: .entries, completion: completion)
    }

    // FIXME: entry deletion fails--but why?
    /* public */ func deleteEntries(_ entries: [BloodGlucoseEntry], completion: @escaping (NightscoutError?) -> Void) {
        delete(entries, from: .entries, completion: completion)
    }

    public func uploadTreatments(_ treatments: [Treatment], completion: @escaping (NightscoutResult<[Treatment]>) -> Void) {
        post(treatments, to: .treatments, completion: completion)
    }

    public func updateTreatments(_ treatments: [Treatment], completion: @escaping (NightscoutError?) -> Void) {
        let modifyGroup = DispatchGroup()
        var error: NightscoutError?

        for treatment in treatments {
            modifyGroup.enter()
            upload(treatment, to: .treatments, httpMethod: .put) { result in
                // TODO: remove this print statement
                if case .success(let response) = result {
                    print(response)
                }
                if case .failure(let err) = result {
                    error = err
                }
                modifyGroup.leave()
            }
        }

        modifyGroup.wait()
        completion(error)
    }

    public func deleteTreatments(_ treatments: [Treatment], completion: @escaping (NightscoutError?) -> Void) {
        delete(treatments, from: .treatments, completion: completion)
    }

    public func deleteProfileRecords(_ records: [ProfileRecord], completion: @escaping (NightscoutError?) -> Void) {
        delete(records, from: .profiles, completion: completion)
    }
}

extension Nightscout {
    private func uploadData<Response>(_ data: Data, to endpoint: APIEndpoint, with request: URLRequest, completion: @escaping (NightscoutResult<Response>) -> Void) {
        let session = urlSession(for: endpoint)
        let task = session.uploadTask(with: request, from: data) { data, response, error in
            if let error = error {
                completion(.failure(.uploadError(error)))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.invalidResponse(reason: "Response received was not an HTTP response")))
                return
            }

            guard let data = data else {
                completion(.failure(.invalidResponse(reason: "Response contained no data")))
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

            do {
                guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? Response else {
                    completion(.failure(.dataParsingFailure(data)))
                    return
                }
                completion(.success(json))
            } catch let error {
                completion(.failure(.jsonParsingError(error)))
            }
        }

        task.resume()
    }

    // TODO: handle result success type better here
    private func upload<T: JSONConvertible>(_ item: T, to endpoint: APIEndpoint, httpMethod: HTTPMethod, completion: @escaping (NightscoutResult<[String: Any]>) -> Void) {
        guard apiSecret != nil else {
            completion(.failure(.missingAPISecret))
            return
        }

        guard let request = configureURLRequest(forEndpoint: endpoint, httpMethod: httpMethod) else {
            completion(.failure(.invalidURL))
            return
        }

        let data: Data
        do {
            data = try item.jsonData()
        } catch {
            completion(.failure(.jsonParsingError(error)))
            return
        }

        uploadData(data, to: endpoint, with: request, completion: completion)
    }

    // TODO: Remove this with conditional conformance in Swift 4.1?
    private func uploadArray<T: JSONConvertible>(_ items: [T], to endpoint: APIEndpoint, httpMethod: HTTPMethod, completion: @escaping (NightscoutResult<[T]>) -> Void) {
        guard apiSecret != nil else {
            completion(.failure(.missingAPISecret))
            return
        }

        guard let request = configureURLRequest(forEndpoint: endpoint, httpMethod: httpMethod) else {
            completion(.failure(.invalidURL))
            return
        }

        let data: Data
        do {
            data = try items.jsonData()
        } catch {
            completion(.failure(.jsonParsingError(error)))
            return
        }

        uploadData(data, to: endpoint, with: request) { (result: NightscoutResult<[JSONDictionary]>) in
            switch result {
            case .success(let rawValues):
                let successfullyUploaded = rawValues.flatMap(T.init(rawValue:))
                completion(.success(successfullyUploaded))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func post<T: JSONConvertible>(_ items: [T], to endpoint: APIEndpoint, completion: @escaping (NightscoutResult<[T]>) -> Void) {
        uploadArray(items, to: endpoint, httpMethod: .post, completion: completion)
    }

    private func delete<T: UniquelyIdentifiable>(_ items: [T], from endpoint: APIEndpoint, completion: @escaping (NightscoutError?) -> Void) {
        let deleteGroup = DispatchGroup()
        var error: NightscoutError?

        for item in items {
            deleteGroup.enter()
            delete(item, from: endpoint) { err in
                if let err = err {
                    error = err
                }
                deleteGroup.leave()
            }
        }

        deleteGroup.wait()
        completion(error)
    }

    private func delete<T: UniquelyIdentifiable>(_ item: T, from endpoint: APIEndpoint, completion: @escaping (NightscoutError?) -> Void) {
        guard apiSecret != nil else {
            completion(.missingAPISecret)
            return
        }

        guard var request = configureURLRequest(forEndpoint: endpoint, httpMethod: .delete) else {
            completion(.invalidURL)
            return
        }

        request.url?.appendPathComponent(item.id)

        fetchData(from: endpoint, with: request) { result in
            completion(result.error)
        }
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

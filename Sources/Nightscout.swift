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
    case unexpectedHTTPResponse(HTTPURLResponse)
    case unexpectedDataFormat(Data)
}

fileprivate enum HTTPMethod: String {
    case get = "GET"
    case put = "PUT"
    case post = "POST"
    case delete = "DELETE"
}

public class Nightscout {
    private let baseURL: URL

    init(baseURL: String) throws {
        guard let baseURL = URL(string: baseURL) else {
            throw NightscoutError.invalidURL
        }
        self.baseURL = baseURL
    }
}

extension Nightscout {
    private enum APIEndpoint: String {
        case entries
        case treatments
        case profile
        case status
        case deviceStatus = "devicestatus"
    }

    private static let apiVersion = "v1"

    private func route(to endpoint: APIEndpoint) -> URL {
        return baseURL.appendingPathComponents("api", Nightscout.apiVersion, endpoint.rawValue).appendingPathExtension("json")
    }
}

extension Nightscout {
    private enum QueryItem {
        case count(Int)
        case date(Operator, Date)

        enum Operator: String {
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
            case .date(let `operator`, let date):
                // use dateString to support both entries and treatments
                let operatorString = (`operator` == .equalTo) ? "" : "[$\(`operator`.rawValue)]"
                let dateString = "\(TimeFormatter.string(from: date)).000Z"
                return URLQueryItem(name: "find[dateString]\(operatorString)", value: dateString)
            }
        }

        static func dateQueries(from dateInterval: DateInterval) -> [QueryItem] {
            return [.date(.greaterThanOrEqualTo, dateInterval.start), .date(.lessThanOrEqualTo, dateInterval.end)]
        }
    }

    private func fetchData(with session: URLSession, from endpoint: APIEndpoint, queries: [QueryItem], completion: @escaping (Result<Data>) -> Void) {
        let queryItems = queries.map { $0.urlQueryItem }
        guard let route = route(to: endpoint).components?.addingQueryItems(queryItems).url else {
            completion(.failure(NightscoutError.invalidURL))
            return
        }

        let task = session.dataTask(with: route) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            let httpResponse = response as! HTTPURLResponse // safe, error was nil and we're making a HTTP request
            guard httpResponse.statusCode == 200, let data = data else {
                completion(.failure(NightscoutError.unexpectedHTTPResponse(httpResponse)))
                return
            }

            completion(.success(data))
        }

        task.resume()
    }

    private func fetch<T: JSONParseable>(with session: URLSession, from endpoint: APIEndpoint, queries: [QueryItem] = [], completion: @escaping (Result<T>) -> Void) {
        fetchData(with: session, from: endpoint, queries: queries) { result in
            switch result {
            case .success(let data):
                do {
                    guard let parsed = try T.parse(from: data) else {
                        completion(.failure(NightscoutError.unexpectedDataFormat(data)))
                        return
                    }
                    completion(.success(parsed))
                } catch let error {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    // TODO: eliminate this method using conditional conformance with Array in Swift 4.1
    private func fetchArray<T: JSONParseable>(with session: URLSession, from endpoint: APIEndpoint, queries: [QueryItem] = [], completion: @escaping (Result<[T]>) -> Void) {
        fetchData(with: session, from: endpoint, queries: queries) { result in
            switch result {
            case .success(let data):
                do {
                    let items = try [T].parse(from: data)
                    completion(.success(items))
                } catch let error {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

extension Nightscout {
    public func snapshot(recentBloodGlucoseEntryCount: Int = 10, recentTreatmentCount: Int = 10, completion: @escaping (Result<NightscoutSnapshot>) -> Void) {
        let date = Date()
        var settings = NightscoutSettings.default
        var bloodGlucoseEntries: [BloodGlucoseEntry] = []
        var treatments: [Treatment] = []
        var profileStoreSnapshots: [ProfileStoreSnapshot] = []
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
        fetchProfileStoreSnapshots { result in
            switch result {
            case .success(let fetchedProfileStoreSnapshots):
                profileStoreSnapshots = fetchedProfileStoreSnapshots
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
            completion(.failure(error))
        } else {
            let snapshot = NightscoutSnapshot(date: date, settings: settings, recentBloodGlucoseEntries: bloodGlucoseEntries, recentTreatments: treatments, profileStoreSnapshots: profileStoreSnapshots)
            completion(.success(snapshot))
        }
    }

    public func fetchSettings(completion: @escaping (Result<NightscoutSettings>) -> Void) {
        fetch(with: .settingsSession, from: .status, completion: completion)
    }

    public func fetchMostRecentEntries(count: Int = 10, completion: @escaping (Result<[BloodGlucoseEntry]>) -> Void) {
        let queries: [QueryItem] = [.count(count)]
        fetchArray(with: .currentEntriesSession, from: .entries, queries: queries, completion: completion)
    }

    public func fetchEntries(from interval: DateInterval, maxCount: Int = .max, completion: @escaping (Result<[BloodGlucoseEntry]>) -> Void) {
        let queries = QueryItem.dateQueries(from: interval) + [.count(maxCount)]
        fetchArray(with: .pastEntriesSession, from: .entries, queries: queries, completion: completion)
    }

    public func fetchMostRecentTreatments(count: Int = 10, completion: @escaping (Result<[Treatment]>) -> Void) {
        let queries: [QueryItem] = [.count(count)]
        fetchArray(with: .currentTreatmentsSession, from: .treatments, queries: queries, completion: completion)
    }

    public func fetchTreatments(from interval: DateInterval, maxCount: Int = .max, completion: @escaping (Result<[Treatment]>) -> Void) {
        let queries = QueryItem.dateQueries(from: interval) + [.count(maxCount)]
        fetchArray(with: .pastTreatmentsSession, from: .treatments, queries: queries, completion: completion)
    }

    public func fetchProfileStoreSnapshots(completion: @escaping (Result<[ProfileStoreSnapshot]>) -> Void) {
        fetchArray(with: .profilesSession, from: .profile, completion: completion)
    }
}

fileprivate extension URLSession {
    static let settingsSession = URLSession(configuration: .default)
    static let currentEntriesSession = URLSession(configuration: .default)
    static let pastEntriesSession = URLSession(configuration: .default)
    static let currentTreatmentsSession = URLSession(configuration: .default)
    static let pastTreatmentsSession = URLSession(configuration: .default)
    static let profilesSession = URLSession(configuration: .default)
}

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
        var snapshot = NightscoutSnapshot(date: Date(), settings: .default, recentBloodGlucoseEntries: [], recentTreatments: [], profileStoreSnapshots: [])
        var error: Error?

        let snapshotGroup = DispatchGroup()

        snapshotGroup.enter()
        fetchSettings { result in
            switch result {
            case .success(let settings):
                snapshot.settings = settings
            case .failure(let err):
                error = err
            }

            snapshotGroup.leave()
        }

        snapshotGroup.enter()
        fetchProfileStoreSnapshots { result in
            switch result {
            case .success(let profileStoreSnapshots):
                snapshot.profileStoreSnapshots = profileStoreSnapshots
            case .failure(let err):
                error = err
            }

            snapshotGroup.leave()
        }

        snapshotGroup.enter()
        fetchEntries(count: recentBloodGlucoseEntryCount, in: nil) { result in
            switch result {
            case .success(let bloodGlucoseEntries):
                snapshot.recentBloodGlucoseEntries = bloodGlucoseEntries
            case .failure(let err):
                error = err
            }

            snapshotGroup.leave()
        }

        snapshotGroup.enter()
        fetchTreatments(count: recentTreatmentCount, in: nil) { result in
            switch result {
            case .success(let treatments):
                snapshot.recentTreatments = treatments
            case .failure(let err):
                error = err
            }

            snapshotGroup.leave()
        }

        snapshotGroup.wait()

        if let error = error {
            completion(.failure(error))
        } else {
            completion(.success(snapshot))
        }
    }

    public func fetchSettings(completion: @escaping (Result<NightscoutSettings>) -> Void) {
        fetch(with: .settingsSession, from: .status, completion: completion)
    }

    public func fetchEntries(count: Int = 10, in interval: DateInterval? = nil, completion: @escaping (Result<[BloodGlucoseEntry]>) -> Void) {
        var queries: [QueryItem] = [.count(count)]
        if let interval = interval {
            queries += QueryItem.dateQueries(from: interval)
        }
        fetchArray(with: .bloodGlucoseEntriesSession, from: .entries, queries: queries, completion: completion)
    }

    public func fetchTreatments(count: Int = 10, in interval: DateInterval? = nil, completion: @escaping (Result<[Treatment]>) -> Void) {
        var queries: [QueryItem] = [.count(count)]
        if let interval = interval {
            queries += QueryItem.dateQueries(from: interval)
        }
        fetchArray(with: .treatmentsSession, from: .treatments, queries: queries, completion: completion)
    }

    public func fetchProfileStoreSnapshots(completion: @escaping (Result<[ProfileStoreSnapshot]>) -> Void) {
        fetchArray(with: .profilesSession, from: .profile, completion: completion)
    }
}

fileprivate extension URLSession {
    static let settingsSession = URLSession(configuration: .default)
    static let bloodGlucoseEntriesSession = URLSession(configuration: .default)
    static let treatmentsSession = URLSession(configuration: .default)
    static let profilesSession = URLSession(configuration: .default)
}

//
//  NightscoutDeviceStatus.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 3/7/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

public struct NightscoutDeviceStatus: UniquelyIdentifiable {
    public let id: String
    public let device: String
    public let date: Date
}

// MARK: - JSON

extension NightscoutDeviceStatus: JSONParseable {
    typealias JSONParseType = JSONDictionary

    enum Key {
        static let id: JSONKey<String> = "_id"
        static let device: JSONKey<String> = "device"
        static let dateString: JSONKey<String> = "created_at"
    }

    static func parse(fromJSON deviceStatusJSON: JSONDictionary) -> NightscoutDeviceStatus? {
        guard
            let id = deviceStatusJSON[Key.id],
            let device = deviceStatusJSON[Key.device],
            let date = deviceStatusJSON[Key.dateString].flatMap(TimeFormatter.date(from:))
        else {
            return nil
        }

        return NightscoutDeviceStatus(
            id: id,
            device: device,
            date: date
        )
    }
}

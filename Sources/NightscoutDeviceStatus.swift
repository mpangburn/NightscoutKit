//
//  NightscoutDeviceStatus.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 3/7/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

public struct NightscoutDeviceStatus: UniquelyIdentifiable {
    enum System {
        case loop(status: LoopDeviceStatus)
        case openAPS(status: OpenAPSDeviceStatus)
    }

    public let id: String
    public let device: String
    public let date: Date
    let system: System
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
            let date = deviceStatusJSON[convertingDateFrom: Key.dateString]
        else {
            return nil
        }

        let system: System
        switch device {
        case _ where device.hasPrefix("loop"):
            guard let status = LoopDeviceStatus.parse(fromJSON: deviceStatusJSON) else {
                return nil
            }
            system = .loop(status: status)
        case _ where device.hasPrefix("openaps"):
            guard let status = OpenAPSDeviceStatus.parse(fromJSON: deviceStatusJSON) else {
                return nil
            }
            system = .openAPS(status: status)
        default :
            return nil
        }

        return NightscoutDeviceStatus(
            id: id,
            device: device,
            date: date,
            system: system
        )
    }
}

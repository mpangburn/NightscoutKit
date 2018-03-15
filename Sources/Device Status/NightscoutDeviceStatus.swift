//
//  NightscoutDeviceStatus.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 3/7/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

public struct NightscoutDeviceStatus: UniquelyIdentifiable {
    public enum ClosedLoopSystem {
        case loop(status: LoopDeviceStatus)
        case openAPS(status: OpenAPSDeviceStatus)

        public var loopStatus: AnyClosedLoopStatus? {
            switch self {
            case .loop(status: let status):
                return status.loopStatus.map(AnyClosedLoopStatus.init)
            case .openAPS(status: let status):
                return .init(status.loopStatus)
            }
        }

        public var pumpStatus: AnyPumpStatus? {
            switch self {
            case .loop(status: let status):
                return status.pumpStatus.map(AnyPumpStatus.init)
            case .openAPS(status: let status):
                return .init(status.pumpStatus)
            }
        }

        public var uploaderStatus: UploaderStatusProtocol? {
            switch self {
            case .loop(status: let status):
                return status.uploaderStatus
            case .openAPS(status: let status):
                return status.uploaderStatus
            }
        }
    }

    public let id: String
    public let device: String
    public let date: Date
    public let closedLoopSystem: ClosedLoopSystem?
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

        let closedLoopSystem: ClosedLoopSystem?
        switch device {
        case _ where device.hasPrefix("loop"):
            closedLoopSystem = LoopDeviceStatus.parse(fromJSON: deviceStatusJSON).map(ClosedLoopSystem.loop)
        case _ where device.hasPrefix("openaps"):
            closedLoopSystem = OpenAPSDeviceStatus.parse(fromJSON: deviceStatusJSON).map(ClosedLoopSystem.openAPS)
        default:
            closedLoopSystem = nil
        }

        return NightscoutDeviceStatus(id: id, device: device, date: date, closedLoopSystem: closedLoopSystem)
    }
}

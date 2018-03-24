//
//  NightscoutDeviceStatus.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 3/7/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Foundation


/// Describes the status of a device in communication with Nightscout.
public struct NightscoutDeviceStatus: UniquelyIdentifiable, TimelineValue {
    /// Describes a closed loop system uploading data to Nightscout.
    public enum ClosedLoopSystem {
        case loop(status: LoopDeviceStatus)
        case openAPS(status: OpenAPSDeviceStatus)

        /// The status of the closed loop.
        public var loopStatus: AnyClosedLoopStatus? {
            switch self {
            case .loop(status: let status):
                return status.loopStatus.map(AnyClosedLoopStatus.init)
            case .openAPS(status: let status):
                return .init(status.loopStatus)
            }
        }

        /// The status of the insulin pump used in the loop.
        public var pumpStatus: AnyPumpStatus? {
            switch self {
            case .loop(status: let status):
                return status.pumpStatus.map(AnyPumpStatus.init)
            case .openAPS(status: let status):
                return .init(status.pumpStatus)
            }
        }

        /// The status of the device uploading the loop status.
        public var uploaderStatus: UploaderStatusProtocol? {
            switch self {
            case .loop(status: let status):
                return status.uploaderStatus
            case .openAPS(status: let status):
                return status.uploaderStatus
            }
        }
    }

    /// The device status's unique, internally assigned identifier.
    public let id: String

    /// The device in communication with Nightscout.
    public let device: String

    /// The date at which the device status was recorded.
    public let date: Date

    /// The closed loop system in communication with Nightscout.
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

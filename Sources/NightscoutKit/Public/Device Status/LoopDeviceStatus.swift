//
//  LoopDeviceStatus.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 3/13/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Foundation


// This structure is pulled more or less directly from Pete Schwamb's NightscoutUploadKit:
// https://github.com/ps2/rileylink_ios/tree/master/NightscoutUploadKit

/// Describes the status of the devices of a Loop closed loop system.
public struct LoopDeviceStatus {
    /// Describes the status of insulin on board.
    public struct InsulinOnBoardStatus: InsulinOnBoardStatusProtocol {
        /// The date at which the status of the insulin on board was recorded.
        public let timestamp: Date

        /// The total insulin on board in units (U),
        /// equal to the sum of the basal and bolus insulin on board.
        public let insulinOnBoard: Double?

        /// The basal insulin on board in units (U).
        public let basalInsulinOnBoard: Double?
    }

    /// Describes the status of a Loop closed loop.
    public struct LoopStatus: ClosedLoopStatusProtocol {
        /// Describes the status of carbs on board.
        public struct CarbsOnBoardStatus {
            /// The date at which the carbs on board were recorded.
            public let timestamp: Date

            /// The carbs on board in grams (g).
            public let carbsOnBoard: Double // TODO: why is this a Double?
        }

        /// Describes the context of predicted blood glucose values based on the status of a closed loop.
        public struct PredictedBloodGlucoseValuesContext {
            /// The reference date from which the predicted glucose values are projected forward.
            public let startDate: Date

            /// The predicted glucose values.
            /// The first member represents the predicted glucose value at the start date,
            /// and each subsequent member represents the predicted glucose five minutes after the previous.
            public let values: [Int]

            /// The projected carbs on board.
            /// The first member represents the carbs on board at the start date,
            /// and each subsequent member represents the carbs on board five minutes after the previous.
            public let carbsOnBoard: [Int]?

            /// The projected insulin on board.
            /// The first member represents the insulin on board at the start date,
            /// and each subsequent member represents the insulin on board five minutes after the previous.
            public let insulinOnBoard: [Int]?

            /// The array of predicted blood glucose values from the context.
            /// Maps each value in `values` to its prediction date.
            public var predictedBloodGlucoseValues: [PredictedBloodGlucoseValue] {
                return .init(values: values, everyFiveMinutesBeginningAt: startDate)
            }
        }

        /// Describes a temporary basal.
        public struct TemporaryBasal: TemporaryBasalProtocol {
            /// The start date of the temporary basal.
            public let startDate: Date

            /// The basal rate in units per hour (U/hr).
            public let rate: Double

            /// The duration of the temporary basal.
            public let duration: TimeInterval
        }

        /// Describes the enacted closed loop.
        public struct LoopEnacted {
            /// The enacted temporary basal.
            public let temporaryBasal: TemporaryBasal

            /// A boolean value describing whether or not the loop was received by the pump.
            public let received: Bool
        }

        /// Describes the status of a RileyLink radio adapter.
        public struct RileyLinkStatus {
            /// Describes the connection state of a RileyLink.
            public enum State: String {
                case connected = "connected"
                case connecting = "connecting"
                case disconnected = "disconnected"
            }

            /// The name of the RileyLink.
            public let name: String

            /// The connection state of the RileyLink.
            public let state: State

            /// The date at which the RileyLink was last idle.
            public let lastIdleDate: Date?

            /// The firmware version of the RileyLink.
            public let version: String?

            /// The received signal strength indicator (RSSI) of the RileyLink.
            public let rssi: Double?
        }

        /// The name of the Loop device.
        public let name: String

        /// The version of Loop in use.
        public let version: String

        /// The date at which the status was recorded.
        public let timestamp: Date

        /// The status of the insulin on board (IOB).
        public let insulinOnBoardStatus: InsulinOnBoardStatus?

        /// The status of the carbs on board (COB).
        public let carbsOnBoardStatus: CarbsOnBoardStatus?

        /// An array of predicted glucose value curves based on the current data.
        public let predictedBloodGlucoseValuesContext: PredictedBloodGlucoseValuesContext?

        /// The temporary basal recommended by the loop.
        public let recommendedTemporaryBasal: TemporaryBasal?

        /// The bolus recommended by the loop.
        public let recommendedBolus: Double?

        /// The loop currently enacted.
        public let loopEnacted: LoopEnacted?

        /// The statuses of the RileyLinks in communication with the loop.
        public let rileyLinkStatuses: [RileyLinkStatus]?

        /// A string describing the reason the loop failed.
        public let failureReason: String?

        /// The carbs on board in grams (g).
        public var carbsOnBoard: Int? {
            return carbsOnBoardStatus.map { Int($0.carbsOnBoard) }
        }

        /// The enacted temporary basal.
        public var enactedTemporaryBasal: TemporaryBasal? {
            return loopEnacted?.temporaryBasal
        }

        /// An array of predicted glucose value curves based on currently available data.
        public var predictedBloodGlucoseCurves: [[PredictedBloodGlucoseValue]]? {
            guard let predictedGlucoseValues = predictedBloodGlucoseValuesContext?.predictedBloodGlucoseValues else {
                return nil
            }
            return [predictedGlucoseValues]
        }
    }

    /// Describes the status of the insulin pump in communication with Loop.
    public struct PumpStatus: PumpStatusProtocol {
        /// Describes the battery status of the pump.
        public struct BatteryStatus: BatteryStatusProtocol {
            /// The percentage of battery remaining.
            public let percentage: Int?

            /// The voltage of the battery.
            public let voltage: Double?

            /// The status of the battery.
            public let status: BatteryIndicator?
        }

        /// The date of the pump clock.
        public let clockDate: Date

        /// The pump ID number.
        public let pumpID: String

        /// The status of the insulin on board.
        public let insulinOnBoardStatus: InsulinOnBoardStatus?

        /// The status of the pump battery.
        public let batteryStatus: BatteryStatus?

        /// A boolean value representing whether the pump is currently suspended.
        public let isSuspended: Bool?

        /// A boolean value representing whether the pump is currently bolusing.
        public let isBolusing: Bool?

        /// The reservoir insulin remaining in units (U).
        public let reservoirInsulinRemaining: Double?
    }

    /// Describes the status of the device uploading Loop data to Nightscout.
    public struct UploaderStatus: UploaderStatusProtocol {
        /// The date at which the device status was recorded.
        public let timestamp: Date

        /// The name of the device.
        public let name: String

        /// The percentage of battery remaining of the uploading device.
        public let batteryPercentage: Int?
    }

    /// Describes a radio adapter in communication with Loop.
    public struct RadioAdapter {
        /// The description of the radio adapter hardware.
        public let hardwareDescription: String

        /// The frequency of the radio adapter.
        public let frequency: Double?

        /// The name of the radio adapter.
        public let name: String?

        /// The date at which the radio adapter was last tuned.
        public let lastTunedDate: Date?

        /// The firmware version of the radio adapter.
        public let firmwareVersion: String

        /// The received signal strength indicator (RSSI) of the radio adapter.
        public let rssi: Int?

        /// The received signal strength indicator (RSSI) of the pump with which the radio adapter is in communication.
        public let pumpRSSI: Int?
    }

    /// The status of the closed loop.
    public let loopStatus: LoopStatus?

    /// The status of the insulin pump used in the loop.
    public let pumpStatus: PumpStatus?

    /// The status of the device uploading the loop status.
    public let uploaderStatus: UploaderStatus?

    /// The status of the radio adapter used in the communication of the loop.
    public let radioAdapter: RadioAdapter?
}

// MARK: - JSON

extension LoopDeviceStatus: JSONParseable {
    private enum Key {
        static let loopStatus: JSONKey<LoopStatus> = "loop"
        static let pumpStatus: JSONKey<PumpStatus> = "pump"
        static let uploaderStatus: JSONKey<UploaderStatus> = "uploader"
        static let radioAdapter: JSONKey<RadioAdapter> = "radioAdapter"
    }

    static func parse(fromJSON json: JSONDictionary) -> LoopDeviceStatus? {
        return .init(
            loopStatus: json[parsingFrom: Key.loopStatus],
            pumpStatus: json[parsingFrom: Key.pumpStatus],
            uploaderStatus: json[parsingFrom: Key.uploaderStatus],
            radioAdapter: json[parsingFrom: Key.radioAdapter]
        )
    }
}

extension LoopDeviceStatus.LoopStatus: JSONParseable {
    private enum Key {
        static let name: JSONKey<String> = "name"
        static let version: JSONKey<String> = "version"
        static let timestampString: JSONKey<String> = "timestamp"
        static let insulinOnBoardStatus: JSONKey<LoopDeviceStatus.InsulinOnBoardStatus> = "iob"
        static let carbsOnBoardStatus: JSONKey<CarbsOnBoardStatus> = "cob"
        static let predictedBloodGlucoseValue: JSONKey<PredictedBloodGlucoseValuesContext> = "predicted"
        static let recommendedTemporaryBasal: JSONKey<TemporaryBasal> = "recommendedTempBasal"
        static let recommendedBolus: JSONKey<Double> = "recommendedBolus"
        static let loopEnacted: JSONKey<LoopEnacted> = "enacted"
        static let rileyLinkStatuses: JSONKey<[RileyLinkStatus]> = "rileylinks"
        static let failureReason: JSONKey<String> = "failureReason"
    }

    static func parse(fromJSON json: JSONDictionary) -> LoopDeviceStatus.LoopStatus? {
        guard
            let name = json[Key.name],
            let version = json[Key.version],
            let timestamp = json[convertingDateFrom: Key.timestampString]
        else {
            return nil
        }

        return .init(
            name: name,
            version: version,
            timestamp: timestamp,
            insulinOnBoardStatus: json[parsingFrom: Key.insulinOnBoardStatus],
            carbsOnBoardStatus: json[parsingFrom: Key.carbsOnBoardStatus],
            predictedBloodGlucoseValuesContext: json[parsingFrom: Key.predictedBloodGlucoseValue],
            recommendedTemporaryBasal: json[parsingFrom: Key.recommendedTemporaryBasal],
            recommendedBolus: json[Key.recommendedBolus],
            loopEnacted: json[parsingFrom: Key.loopEnacted],
            rileyLinkStatuses: json[parsingFrom: Key.rileyLinkStatuses],
            failureReason: json[Key.failureReason]
        )
    }
}

extension LoopDeviceStatus.InsulinOnBoardStatus: JSONParseable {
    private enum Key {
        static let timestampString: JSONKey<String> = "timestamp"
        static let insulinOnBoard: JSONKey<Double> = "iob"
        static let basalInsulinOnBoard: JSONKey<Double> = "basaliob"
    }

    static func parse(fromJSON json: JSONDictionary) -> LoopDeviceStatus.InsulinOnBoardStatus? {
        guard let timestamp = json[convertingDateFrom: Key.timestampString] else {
            return nil
        }

        return .init(
            timestamp: timestamp,
            insulinOnBoard: json[Key.insulinOnBoard],
            basalInsulinOnBoard: json[Key.basalInsulinOnBoard]
        )
    }
}

extension LoopDeviceStatus.LoopStatus.CarbsOnBoardStatus: JSONParseable {
    private enum Key {
        static let timestampString: JSONKey<String> = "timestamp"
        static let carbsOnBoard: JSONKey<Double> = "cob"
    }

    static func parse(fromJSON json: JSONDictionary) -> LoopDeviceStatus.LoopStatus.CarbsOnBoardStatus? {
        guard
            let timestamp = json[convertingDateFrom: Key.timestampString],
            let carbsOnBoard = json[Key.carbsOnBoard]
        else {
            return nil
        }

        return .init(timestamp: timestamp, carbsOnBoard: carbsOnBoard)
    }
}

extension LoopDeviceStatus.LoopStatus.PredictedBloodGlucoseValuesContext: JSONParseable {
    private enum Key {
        static let startDateString: JSONKey<String> = "startDate"
        static let values: JSONKey<[Int]> = "values"
        static let carbsOnBoard: JSONKey<[Int]> = "COB"
        static let insulinOnBoard: JSONKey<[Int]> = "IOB"
    }

    static func parse(fromJSON json: JSONDictionary) -> LoopDeviceStatus.LoopStatus.PredictedBloodGlucoseValuesContext? {
        guard
            let startDate = json[convertingDateFrom: Key.startDateString],
            let values = json[Key.values]
        else {
            return nil
        }

        return .init(
            startDate: startDate,
            values: values,
            carbsOnBoard: json[Key.carbsOnBoard],
            insulinOnBoard: json[Key.insulinOnBoard]
        )
    }
}

extension LoopDeviceStatus.LoopStatus.TemporaryBasal: JSONParseable {
    private enum Key {
        static let startDateString: JSONKey<String> = "timestamp"
        static let rate: JSONKey<Double> = "rate"
        static let durationInMinutes: JSONKey<Double> = "duration"
    }

    static func parse(fromJSON json: JSONDictionary) -> LoopDeviceStatus.LoopStatus.TemporaryBasal? {
        guard
            let startDate = json[convertingDateFrom: Key.startDateString],
            let rate = json[Key.rate],
            let duration = json[Key.durationInMinutes].map(TimeInterval.minutes)
        else {
            return nil
        }

        return .init(startDate: startDate, rate: rate, duration: duration)
    }
}

extension LoopDeviceStatus.LoopStatus.LoopEnacted: JSONParseable {
    private enum Key {
        static let received: JSONKey<Bool> = "received"
    }

    static func parse(fromJSON json: JSONDictionary) -> LoopDeviceStatus.LoopStatus.LoopEnacted? {
        guard
            let received = json[Key.received],
            let temporaryBasal = LoopDeviceStatus.LoopStatus.TemporaryBasal.parse(fromJSON: json)
        else {
            return nil
        }

        return .init(temporaryBasal: temporaryBasal, received: received)
    }
}

extension LoopDeviceStatus.LoopStatus.RileyLinkStatus: JSONParseable {
    private enum Key {
        static let name: JSONKey<String> = "name"
        static let state: JSONKey<State> = "state"
        static let lastIdleDateString: JSONKey<String> = "lastIdle"
        static let version: JSONKey<String> = "version"
        static let rssi: JSONKey<Double> = "rssi"
    }

    static func parse(fromJSON json: JSONDictionary) -> LoopDeviceStatus.LoopStatus.RileyLinkStatus? {
        guard
            let name = json[Key.name],
            let state = json[convertingFrom: Key.state]
        else {
            return nil
        }

        return .init(
            name: name,
            state: state,
            lastIdleDate: json[convertingDateFrom: Key.lastIdleDateString],
            version: json[Key.version],
            rssi: json[Key.rssi]
        )
    }
}

extension LoopDeviceStatus.PumpStatus: JSONParseable {
    private enum Key {
        static let clockDateString: JSONKey<String> = "clock"
        static let pumpID: JSONKey<String> = "pumpID"
        static let insulinOnBoardStatus: JSONKey<LoopDeviceStatus.InsulinOnBoardStatus> = "iob"
        static let batteryStatus: JSONKey<BatteryStatus> = "battery"
        static let isSuspended: JSONKey<Bool> = "suspended"
        static let isBolusing: JSONKey<Bool> = "bolusing"
        static let reservoirInsulinRemaining: JSONKey<Double> = "reservoir"
    }

    static func parse(fromJSON json: JSONDictionary) -> LoopDeviceStatus.PumpStatus? {
        guard
            let clockDate = json[convertingDateFrom: Key.clockDateString],
            let pumpID = json[Key.pumpID]
        else {
            return nil
        }

        return .init(
            clockDate: clockDate,
            pumpID: pumpID,
            insulinOnBoardStatus: json[parsingFrom: Key.insulinOnBoardStatus],
            batteryStatus: json[parsingFrom: Key.batteryStatus],
            isSuspended: json[Key.isSuspended],
            isBolusing: json[Key.isBolusing],
            reservoirInsulinRemaining: json[Key.reservoirInsulinRemaining]
        )
    }
}

extension LoopDeviceStatus.PumpStatus.BatteryStatus: JSONParseable {
    private enum Key {
        static let percentage: JSONKey<Int> = "percent"
        static let voltage: JSONKey<Double> = "voltage"
        static let status: JSONKey<BatteryIndicator> = "status"
    }

    static func parse(fromJSON json: JSONDictionary) -> LoopDeviceStatus.PumpStatus.BatteryStatus? {
        return .init(
            percentage: json[Key.percentage],
            voltage: json[Key.voltage],
            status: json[convertingFrom: Key.status]
        )
    }
}

extension LoopDeviceStatus.UploaderStatus: JSONParseable {
    private enum Key {
        static let timestampString: JSONKey<String> = "timestamp"
        static let name: JSONKey<String> = "name"
        static let batteryPercentage: JSONKey<Int> = "battery"
    }

    static func parse(fromJSON json: JSONDictionary) -> LoopDeviceStatus.UploaderStatus? {
        guard
            let timestamp = json[convertingDateFrom: Key.timestampString],
            let name = json[Key.name]
        else {
            return nil
        }

        return .init(
            timestamp: timestamp,
            name: name,
            batteryPercentage: json[Key.batteryPercentage]
        )
    }
}

extension LoopDeviceStatus.RadioAdapter: JSONParseable {
    private enum Key {
        static let hardwareDescription: JSONKey<String> = "hardware"
        static let frequency: JSONKey<Double> = "frequency"
        static let name: JSONKey<String> = "name"
        static let lastTunedDateString: JSONKey<String> = "lastTuned"
        static let firmwareVersion: JSONKey<String> = "firmwareVersion"
        static let rssi: JSONKey<Int> = "RSSI"
        static let pumpRSSI: JSONKey<Int> = "pumpRSSI"
    }

    static func parse(fromJSON json: JSONDictionary) -> LoopDeviceStatus.RadioAdapter? {
        guard
            let hardwareDescription = json[Key.hardwareDescription],
            let firmwareVersion = json[Key.firmwareVersion]
        else {
            return nil
        }

        return .init(
            hardwareDescription: hardwareDescription,
            frequency: json[Key.frequency],
            name: json[Key.name],
            lastTunedDate: json[convertingDateFrom: Key.lastTunedDateString],
            firmwareVersion: firmwareVersion,
            rssi: json[Key.rssi],
            pumpRSSI: json[Key.pumpRSSI]
        )
    }
}

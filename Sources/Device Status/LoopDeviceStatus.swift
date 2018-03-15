//
//  LoopDeviceStatus.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 3/13/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

// This structure is pulled pretty much directly from Pete Schwamb's NightscoutUploadKit:
// https://github.com/ps2/rileylink_ios/tree/master/NightscoutUploadKit
// NightscoutUploadKit could be introduced as a dependency, but it has some reliance
// on HealthKit, which can't be supported if NightscoutKit is to support all Apple platforms
public struct LoopDeviceStatus {
    public struct InsulinOnBoardStatus: InsulinOnBoardStatusProtocol {
        public let timestamp: Date
        public let insulinOnBoard: Double?
        public let basalInsulinOnBoard: Double?
    }

    public struct LoopStatus: ClosedLoopStatusProtocol {
        public struct CarbsOnBoardStatus {
            public let timestamp: Date
            public let carbsOnBoard: Double
        }

        public struct PredictedBloodGlucoseValuesContext {
            public let startDate: Date
            public let values: [Int]
            public let carbsOnBoard: [Int]?
            public let insulinOnBoard: [Int]?

            public var predictedBloodGlucoseValues: [PredictedBloodGlucoseValue] {
                return Array<PredictedBloodGlucoseValue>(mgdlValues: values, everyFiveMinutesBeginningAt: startDate)
            }
        }

        public struct TemporaryBasal: TemporaryBasalProtocol {
            public let startDate: Date
            public let rate: Double
            public let duration: TimeInterval
        }

        public struct LoopEnacted {
            public let temporaryBasal: TemporaryBasal
            public let received: Bool
        }

        public struct RileyLinkStatus {
            public enum State: String {
                case connected = "connected"
                case connecting = "connecting"
                case disconnected = "disconnected"
            }

            public let name: String
            public let state: State
            public let lastIdleDate: Date?
            public let version: String?
            public let rssi: Double?
        }

        public let name: String
        public let version: String
        public let timestamp: Date
        public let insulinOnBoardStatus: InsulinOnBoardStatus?
        public let carbsOnBoardStatus: CarbsOnBoardStatus?
        public let predictedBloodGlucoseValuesContext: PredictedBloodGlucoseValuesContext?
        public let recommendedTemporaryBasal: TemporaryBasal?
        public let recommendedBolus: Double?
        public let loopEnacted: LoopEnacted?
        public let rileyLinkStatuses: [RileyLinkStatus]?
        public let failureReason: String?

        public var carbsOnBoard: Int? {
            guard let carbsOnBoard = carbsOnBoardStatus?.carbsOnBoard else {
                return nil
            }
            return Int(carbsOnBoard)
        }

        public var enactedTemporaryBasal: TemporaryBasal? {
            return loopEnacted?.temporaryBasal
        }

        public var predictedBloodGlucoseCurves: [[PredictedBloodGlucoseValue]]? {
            guard let predictedGlucoseValues = predictedBloodGlucoseValuesContext?.predictedBloodGlucoseValues else {
                return nil
            }
            return [predictedGlucoseValues]
        }
    }

    public struct PumpStatus: PumpStatusProtocol {
        public struct BatteryStatus: BatteryStatusProtocol {
            public let percentage: Int?
            public let voltage: Double?
            public let status: BatteryIndicator?
        }

        public let clockDate: Date
        public let pumpID: String
        public let insulinOnBoardStatus: InsulinOnBoardStatus?
        public let batteryStatus: BatteryStatus?
        public let isSuspended: Bool?
        public let isBolusing: Bool?
        public let reservoirInsulinRemaining: Double?
    }

    public struct UploaderStatus: UploaderStatusProtocol {
        public let timestamp: Date
        public let name: String
        public let batteryPercentage: Int?
    }

    public struct RadioAdapter {
        public let hardwareDescription: String
        public let frequency: Double?
        public let name: String?
        public let lastTunedDate: Date?
        public let firmwareVersion: String
        public let rssi: Int?
        public let pumpRSSI: Int?
    }

    public let loopStatus: LoopStatus?
    public let pumpStatus: PumpStatus?
    public let uploaderStatus: UploaderStatus?
    public let radioAdapter: RadioAdapter?
}

// MARK: - JSON

extension LoopDeviceStatus: JSONParseable {
    typealias JSONParseType = JSONDictionary

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
    typealias JSONParseType = JSONDictionary

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
        // TODO: use make this a [RileyLinkStatus] key once we have conditional conformance
        static let rileyLinkStatuses: JSONKey<[JSONDictionary]> = "rileylinks"
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
            rileyLinkStatuses: json[Key.rileyLinkStatuses]?.flatMap(RileyLinkStatus.parse(fromJSON:)),
            failureReason: json[Key.failureReason]
        )
    }
}

extension LoopDeviceStatus.InsulinOnBoardStatus: JSONParseable {
    typealias JSONParseType = JSONDictionary

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
    typealias JSONParseType = JSONDictionary

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
    typealias JSONParseType = JSONDictionary

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
    typealias JSONParseType = JSONDictionary

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
    typealias JSONParseType = JSONDictionary

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
    typealias JSONParseType = JSONDictionary

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
    typealias JSONParseType = JSONDictionary

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
    typealias JSONParseType = JSONDictionary

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
    typealias JSONParseType = JSONDictionary

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
    typealias JSONParseType = JSONDictionary

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

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
// on HealthKit, which can't be supported if NightscoutKit is to support macOS
struct LoopDeviceStatus {
    struct InsulinOnBoardStatus {
        let timestamp: Date
        let insulinOnBoard: Double?
        let basalInsulinOnBoard: Double?

        var bolusInsulinOnBoard: Double? {
            guard let insulinOnBoard = insulinOnBoard, let basalInsulinOnBoard = basalInsulinOnBoard else {
                return nil
            }

            return insulinOnBoard - basalInsulinOnBoard
        }
    }

    struct LoopStatus {
        struct CarbsOnBoardStatus {
            let timestamp: Date
            let carbsOnBoard: Double
        }

        struct PredictedBloodGlucoseValues {
            let startDate: Date
            let values: [Int]
            let carbsOnBoard: [Int]?
            let insulinOnBoard: [Int]?
        }

        struct TemporaryBasal {
            let startDate: Date
            let rate: Double
            let duration: TimeInterval
        }

        struct LoopEnacted {
            let timestamp: Date
            let rate: Double
            let duration: TimeInterval
            let received: Bool
        }

        struct RileyLinkStatus {
            enum State: String {
                case connected = "connected"
                case connecting = "connecting"
                case disconnected = "disconnected"
            }

            let name: String
            let state: State
            let lastIdleDate: Date?
            let version: String?
            let rssi: Double?
        }

        let name: String
        let version: String
        let timestamp: Date
        let insulinOnBoardStatus: InsulinOnBoardStatus?
        let carbsOnBoardStatus: CarbsOnBoardStatus?
        let predictedBloodGlucoseValue: PredictedBloodGlucoseValues?
        let recommendedBolus: Double?
        let loopEnacted: LoopEnacted?
        let rileyLinkStatuses: [RileyLinkStatus]?
        let failureReason: String?
    }

    struct PumpStatus {
        struct BatteryStatus {
            enum BatteryIndicator: String {
                case low = "low"
                case normal = "normal"
            }

            let percent: Int?
            let voltage: Double?
            let status: BatteryIndicator?
        }

        let clockDate: Date
        let pumpID: String
        let insulinOnBoardStatus: InsulinOnBoardStatus?
        let batteryStatus: BatteryStatus?
        let isSuspended: Bool
        let isBolusing: Bool
        let reservoirInsulinRemaining: Double?
    }

    struct UploaderStatus {
        let timestamp: Date
        let name: String
        let battery: Int?
    }

    struct RadioAdapter {
        let hardwareDescription: String
        let frequency: Double?
        let name: String?
        let lastTunedDate: Date?
        let firmwareVersion: String
        let rssi: Int?
        let pumpRSSI: Int?
    }

    let loopStatus: LoopStatus?
    let pumpStatus: PumpStatus?
    let uploaderStatus: UploaderStatus?
    let radioAdapter: RadioAdapter?
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
        static let predictedBloodGlucoseValue: JSONKey<PredictedBloodGlucoseValues> = "predicted"
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
            predictedBloodGlucoseValue: json[parsingFrom: Key.predictedBloodGlucoseValue],
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

extension LoopDeviceStatus.LoopStatus.PredictedBloodGlucoseValues: JSONParseable {
    typealias JSONParseType = JSONDictionary

    private enum Key {
        static let startDateString: JSONKey<String> = "startDate"
        static let values: JSONKey<[Int]> = "values"
        static let carbsOnBoard: JSONKey<[Int]> = "COB"
        static let insulinOnBoard: JSONKey<[Int]> = "IOB"
    }

    static func parse(fromJSON json: JSONDictionary) -> LoopDeviceStatus.LoopStatus.PredictedBloodGlucoseValues? {
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
        static let timestampString: JSONKey<String> = "timestamp"
        static let rate: JSONKey<Double> = "rate"
        static let durationInMinutes: JSONKey<Double> = "duration"
        static let received: JSONKey<Bool> = "received"
    }

    static func parse(fromJSON json: JSONDictionary) -> LoopDeviceStatus.LoopStatus.LoopEnacted? {
        guard
            let timestamp = json[convertingDateFrom: Key.timestampString],
            let rate = json[Key.rate],
            let duration = json[Key.durationInMinutes].map(TimeInterval.minutes),
            let received = json[Key.received]
        else {
            return nil
        }

        return .init(timestamp: timestamp, rate: rate, duration: duration, received: received)
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
            isSuspended: json[Key.isSuspended] ?? false,
            isBolusing: json[Key.isBolusing] ?? false,
            reservoirInsulinRemaining: json[Key.reservoirInsulinRemaining]
        )
    }
}

extension LoopDeviceStatus.PumpStatus.BatteryStatus: JSONParseable {
    typealias JSONParseType = JSONDictionary

    private enum Key {
        static let percent: JSONKey<Int> = "percent"
        static let voltage: JSONKey<Double> = "voltage"
        static let status: JSONKey<BatteryIndicator> = "status"
    }

    static func parse(fromJSON json: JSONDictionary) -> LoopDeviceStatus.PumpStatus.BatteryStatus? {
        return .init(
            percent: json[Key.percent],
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
        static let battery: JSONKey<Int> = "battery"
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
            battery: json[Key.battery]
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

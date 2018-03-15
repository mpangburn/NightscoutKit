//
//  OpenAPSDeviceStatus.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 3/8/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

public struct OpenAPSDeviceStatus {
    public struct LoopStatus: ClosedLoopStatusProtocol {
        public struct Bolus {
            public let amount: Double
            public let date: Date
        }

        public struct TemporaryBasal: TemporaryBasalProtocol {
            public let startDate: Date
            public let rate: Double
            public let duration: TimeInterval
        }

        public struct InsulinOnBoardStatus: InsulinOnBoardStatusProtocol {
            public let insulinOnBoard: Double?
            public let recentInsulinActivity: Double // (net IOB 1 min ago) - (net IOB now)
            public let basalInsulinOnBoard: Double?
            public let bolusInsulinOnBoard: Double?
            public let lastBolus: Bolus
            public let lastTemporaryBasal: TemporaryBasal
            public let timestamp: Date
        }

        public struct Context {
            public struct State {
                public struct PredictedBloodGlucoseValues {
                    public let basedOnInsulinOnBoard: [Int]
                    public let withZeroBasal: [Int]
                    public let basedOnCarbAbsorption: [Int]?
                }

                public let bloodGlucoseValue: Int
                public let deltaFromLastBloodGlucoseValue: Int
                public let predictedEventualBloodGlucoseValue: Int
                public let temporaryBasal: TemporaryBasal?
                public let received: Bool
                public let sensitivityRatio: Double
                public let predictedBloodGlucoseValues: PredictedBloodGlucoseValues?
                public let carbsOnBoard: Int
                public let insulinOnBoard: Double
            }

            public let state: State?
            public let reason: String
            public let timestamp: Date

            public var predictedBloodGlucoseCurves: [[PredictedBloodGlucoseValue]]? {
                let predictionCurves = state?.predictedBloodGlucoseValues.map {
                    [$0.basedOnInsulinOnBoard, $0.withZeroBasal, $0.basedOnCarbAbsorption].flatMap { $0 }
                }
                return predictionCurves?.map {
                    Array<PredictedBloodGlucoseValue>(mgdlValues: $0, everyFiveMinutesBeginningAt: timestamp)
                }
            }
        }

        public let insulinOnBoardStatus: InsulinOnBoardStatus?
        public let suggested: Context
        public let enacted: Context

        public var timestamp: Date {
            return enacted.timestamp
        }

        public var carbsOnBoard: Int? {
            return enacted.state?.carbsOnBoard
        }

        public var enactedTemporaryBasal: TemporaryBasal? {
            return enacted.state?.temporaryBasal
        }

        public var recommendedTemporaryBasal: TemporaryBasal? {
            return suggested.state?.temporaryBasal
        }

        public var predictedBloodGlucoseCurves: [[PredictedBloodGlucoseValue]]? {
            return enacted.predictedBloodGlucoseCurves ?? suggested.predictedBloodGlucoseCurves
        }
    }

    public struct PumpStatus: PumpStatusProtocol {
        public struct BatteryStatus: BatteryStatusProtocol {
            public let status: BatteryIndicator?
            public let voltage: Double?
        }

        public let clockDate: Date
        public let reservoirInsulinRemaining: Double?
        public let batteryStatus: BatteryStatus?
        public let stateDescription: String? // TODO: enum? one case is "normal"
        public let isBolusing: Bool?
        public let isSuspended: Bool?
        public let timestamp: Date?
    }

    public struct UploaderStatus: UploaderStatusProtocol {
        public let batteryVoltage: Int
        public let batteryPercentage: Int?
    }

    public let loopStatus: LoopStatus
    public let pumpStatus: PumpStatus
    public let uploaderStatus: UploaderStatus
}

// MARK: - JSON

extension OpenAPSDeviceStatus: JSONParseable {
    typealias JSONParseType = JSONDictionary

    private enum Key {
        static let loopStatus: JSONKey<LoopStatus> = "openaps"
        static let pumpStatus: JSONKey<PumpStatus> = "pump"
        static let uploaderStatus: JSONKey<UploaderStatus> = "uploader"
    }

    static func parse(fromJSON deviceStatusJSON: JSONDictionary) -> OpenAPSDeviceStatus? {
        guard
            let loopStatus = deviceStatusJSON[parsingFrom: Key.loopStatus],
            let pumpStatus = deviceStatusJSON[parsingFrom: Key.pumpStatus],
            let uploaderStatus = deviceStatusJSON[parsingFrom: Key.uploaderStatus]
        else {
            return nil
        }

        return .init(loopStatus: loopStatus, pumpStatus: pumpStatus, uploaderStatus: uploaderStatus)
    }
}

extension OpenAPSDeviceStatus.LoopStatus: JSONParseable {
    typealias JSONParseType = JSONDictionary

    private enum Key {
        static let insulinOnBoardStatus: JSONKey<InsulinOnBoardStatus> = "iob"
        static let suggested: JSONKey<Context> = "suggested"
        static let enacted: JSONKey<Context> = "enacted"
    }

    static func parse(fromJSON json: JSONDictionary) -> OpenAPSDeviceStatus.LoopStatus? {
        guard
            let suggested = json[parsingFrom: Key.suggested],
            let enacted = json[parsingFrom: Key.enacted]
        else {
            return nil
        }

        return .init(
            insulinOnBoardStatus: json[parsingFrom: Key.insulinOnBoardStatus],
            suggested: suggested,
            enacted: enacted
        )
    }
}

extension OpenAPSDeviceStatus.LoopStatus.InsulinOnBoardStatus: JSONParseable {
    typealias JSONParseType = JSONDictionary

    private enum Key {
        static let insulinOnBoard: JSONKey<Double> = "iob"
        static let recentInsulinActivity: JSONKey<Double> = "activity"
        static let basalInsulinOnBoard: JSONKey<Double> = "basaliob"
        static let bolusInsulinOnBoard: JSONKey<Double> = "bolusiob"
        static let lastTemporaryBasal: JSONKey<OpenAPSDeviceStatus.LoopStatus.TemporaryBasal> = "lastTemp"
        static let timestampString: JSONKey<String> = "timestamp"
    }

    static func parse(fromJSON json: JSONDictionary) -> OpenAPSDeviceStatus.LoopStatus.InsulinOnBoardStatus? {
        guard
            let recentInsulinActivity = json[Key.recentInsulinActivity],
            let lastBolus = OpenAPSDeviceStatus.LoopStatus.Bolus.parse(fromJSON: json),
            let lastTemporaryBasal = json[parsingFrom: Key.lastTemporaryBasal],
            let timestamp = json[convertingDateFrom: Key.timestampString]
        else {
            return nil
        }

        return .init(
            insulinOnBoard: json[Key.insulinOnBoard],
            recentInsulinActivity: recentInsulinActivity,
            basalInsulinOnBoard: json[Key.basalInsulinOnBoard],
            bolusInsulinOnBoard: json[Key.bolusInsulinOnBoard],
            lastBolus: lastBolus,
            lastTemporaryBasal: lastTemporaryBasal,
            timestamp: timestamp
        )
    }
}

extension OpenAPSDeviceStatus.LoopStatus.Bolus: JSONParseable {
    typealias JSONParseType = JSONDictionary

    private enum Key {
        static let amount: JSONKey<Double> = "bolusinsulin"
        static let date: JSONKey<Int> = "lastBolusTime"
    }

    static func parse(fromJSON json: JSONDictionary) -> OpenAPSDeviceStatus.LoopStatus.Bolus? {
        guard
            let amount = json[Key.amount],
            let date = json[Key.date].map(TimeInterval.init).map(Date.init(timeIntervalSince1970:))
        else {
            return nil
        }

        return .init(amount: amount, date: date)
    }
}

extension OpenAPSDeviceStatus.LoopStatus.TemporaryBasal: JSONParseable {
    typealias JSONParseType = JSONDictionary

    private enum Key {
        static let startDateString: JSONKey<String> = "started_at"
        static let rate: JSONKey<Double> = "rate"
        static let durationInMinutes: JSONKey<Double> = "duration"
    }

    fileprivate static func parse(fromJSON json: JSONDictionary, withDateStringKey dateStringKey: JSONKey<String>) -> OpenAPSDeviceStatus.LoopStatus.TemporaryBasal? {
        guard
            let startDate = json[convertingDateFrom: dateStringKey],
            let rate = json[Key.rate],
            let duration = json[Key.durationInMinutes].map(TimeInterval.minutes)
        else {
            return nil
        }

        return .init(startDate: startDate, rate: rate, duration: duration)
    }

    static func parse(fromJSON json: JSONDictionary) -> OpenAPSDeviceStatus.LoopStatus.TemporaryBasal? {
        return parse(fromJSON: json, withDateStringKey: Key.startDateString)
    }
}

extension OpenAPSDeviceStatus.LoopStatus.Context: JSONParseable {
    typealias JSONParseType = JSONDictionary

    private enum Key {
        static let reason: JSONKey<String> = "reason"
        static let timestampString: JSONKey<String> = "timestamp"
    }

    static func parse(fromJSON json: JSONDictionary) -> OpenAPSDeviceStatus.LoopStatus.Context? {
        guard
            let reason = json[Key.reason],
            let timestamp = json[convertingDateFrom: Key.timestampString]
        else {
            return nil
        }

        return .init(
            state: State.parse(fromJSON: json),
            reason: reason,
            timestamp: timestamp
        )
    }
}

extension OpenAPSDeviceStatus.LoopStatus.Context.State: JSONParseable {
    typealias JSONParseType = JSONDictionary

    private enum Key {
        static let bloodGlucoseValue: JSONKey<Int> = "bg"
        static let deltaFromLastBloodGlucoseValue: JSONKey<Int> = "tick"
        static let deltaFromLastBloodGlucoseValueString: JSONKey<String> = "tick" // sometimes delta comes in as a string (e.g. "+3") and sometimes as an int (e.g. -1)
        static let predictedEventualBloodGlucoseValue: JSONKey<Int> = "eventualBG"
        static let deliveryDateString: JSONKey<String> = "deliverAt"
        static let received: JSONKey<Bool> = "recieved" // yes, "received" really is misspelled
        static let sensitivityRatio: JSONKey<Double> = "sensitivityRatio"
        static let predictedBloodGlucoseValuesJSON: JSONKey<PredictedBloodGlucoseValues> = "predBGs"
        static let carbsOnBoard: JSONKey<Int> = "COB"
        static let insulinOnBoard: JSONKey<Double> = "IOB"
    }

    static func parse(fromJSON json: JSONDictionary) -> OpenAPSDeviceStatus.LoopStatus.Context.State? {
        guard
            let bloodGlucoseValue = json[Key.bloodGlucoseValue],
            let predictedEventualBloodGlucoseValue = json[Key.predictedEventualBloodGlucoseValue],
            let sensitivityRatio = json[Key.sensitivityRatio],
            let carbsOnBoard = json[Key.carbsOnBoard],
            let insulinOnBoard = json[Key.insulinOnBoard]
        else {
            return nil
        }

        guard let deltaFromLastBloodGlucoseValue: Int = {
            if let deltaFromLastBloodGlucoseValue = json[Key.deltaFromLastBloodGlucoseValue] {
                return deltaFromLastBloodGlucoseValue
            } else if let deltaFromLastBloodGlucoseValue = json[Key.deltaFromLastBloodGlucoseValueString].flatMap(Int.init) {
                return deltaFromLastBloodGlucoseValue
            } else {
                return nil
            }
        }() else {
            return nil
        }

        return .init(
            bloodGlucoseValue: bloodGlucoseValue,
            deltaFromLastBloodGlucoseValue: deltaFromLastBloodGlucoseValue,
            predictedEventualBloodGlucoseValue: predictedEventualBloodGlucoseValue,
            temporaryBasal: OpenAPSDeviceStatus.LoopStatus.TemporaryBasal.parse(fromJSON: json, withDateStringKey: Key.deliveryDateString),
            received: json[Key.received] ?? false,
            sensitivityRatio: sensitivityRatio,
            predictedBloodGlucoseValues: json[parsingFrom: Key.predictedBloodGlucoseValuesJSON],
            carbsOnBoard: carbsOnBoard,
            insulinOnBoard: insulinOnBoard
        )
    }
}

extension OpenAPSDeviceStatus.LoopStatus.Context.State.PredictedBloodGlucoseValues: JSONParseable {
    typealias JSONParseType = JSONDictionary

    private enum Key {
        static let basedOnInsulinOnBoard: JSONKey<[Int]> = "IOB"
        static let withZeroBasal: JSONKey<[Int]> = "ZT"
        static let basedOnCarbAbsorption: JSONKey<[Int]> = "COB"
    }

    static func parse(fromJSON json: JSONDictionary) -> OpenAPSDeviceStatus.LoopStatus.Context.State.PredictedBloodGlucoseValues? {
        guard
            let basedOnInsulinOnBoard = json[Key.basedOnInsulinOnBoard],
            let withZeroBasal = json[Key.withZeroBasal]
        else {
            return nil
        }

        return .init(
            basedOnInsulinOnBoard: basedOnInsulinOnBoard,
            withZeroBasal: withZeroBasal,
            basedOnCarbAbsorption: json[Key.basedOnCarbAbsorption]
        )
    }
}

extension OpenAPSDeviceStatus.PumpStatus: JSONParseable {
    typealias JSONParseType = JSONDictionary

    private enum Key {
        static let clockDateString: JSONKey<String> = "clock"
        static let batteryStatus: JSONKey<BatteryStatus> = "battery"
        static let reservoirInsulinRemaining: JSONKey<Double> = "reservoir"
        static let statusJSON: JSONKey<JSONDictionary> = "status"
        static let stateDescription: JSONKey<String> = "status"
        static let isBolusing: JSONKey<Bool> = "bolusing"
        static let isSuspended: JSONKey<Bool> = "suspended"
        static let timestampString: JSONKey<String> = "timestamp"
    }

    static func parse(fromJSON json: JSONDictionary) -> OpenAPSDeviceStatus.PumpStatus? {
        guard let clockDate = json[convertingDateFrom: Key.clockDateString] else {
            return nil
        }

        let statusJSON = json[Key.statusJSON]

        return .init(
            clockDate: clockDate,
            reservoirInsulinRemaining: json[Key.reservoirInsulinRemaining],
            batteryStatus: json[parsingFrom: Key.batteryStatus],
            stateDescription: statusJSON?[Key.stateDescription],
            isBolusing: statusJSON?[Key.isBolusing],
            isSuspended: statusJSON?[Key.isSuspended],
            timestamp: statusJSON?[convertingDateFrom: Key.timestampString]
        )
    }
}

extension OpenAPSDeviceStatus.PumpStatus.BatteryStatus: JSONParseable {
    typealias JSONParseType = JSONDictionary

    private enum Key {
        static let status: JSONKey<BatteryIndicator> = "status"
        static let voltage: JSONKey<Double> = "voltage"
    }

    static func parse(fromJSON json: JSONDictionary) -> OpenAPSDeviceStatus.PumpStatus.BatteryStatus? {
        return .init(
            status: json[convertingFrom: Key.status],
            voltage: json[Key.voltage]
        )
    }
}

extension OpenAPSDeviceStatus.UploaderStatus: JSONParseable {
    typealias JSONParseType = JSONDictionary

    private enum Key {
        static let batteryVoltage: JSONKey<Int> = "batteryVoltage"
        static let batteryPercentage: JSONKey<Int> = "battery"
    }

    static func parse(fromJSON json: JSONDictionary) -> OpenAPSDeviceStatus.UploaderStatus? {
        guard let batteryVoltage = json[Key.batteryVoltage] else {
            return nil
        }

        return .init(
            batteryVoltage: batteryVoltage,
            batteryPercentage: json[Key.batteryPercentage]
        )
    }
}

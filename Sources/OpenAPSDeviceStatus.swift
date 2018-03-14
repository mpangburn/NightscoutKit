//
//  OpenAPSDeviceStatus.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 3/8/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

public struct OpenAPSDeviceStatus {
    public struct ClosedLoopStatus {
        public struct Bolus {
            public let amount: Double
            public let date: Date
        }

        public struct TemporaryBasal {
            public let rate: Double
            public let startDate: Date
            public let duration: TimeInterval
        }

        public struct ActiveInsulinContext {
            public let insulinOnBoard: Double
            public let recentInsulinActivity: Double // (net IOB 1 min ago) - (net IOB now)
            public let basalInsulinOnBoard: Double
            public let bolusInsulinOnBoard: Double
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
        }

        public let activeInsulinContext: ActiveInsulinContext?
        public let suggested: Context
        public let enacted: Context
    }

    public struct PumpStatus {
        public struct Battery {
            public let status: String // TODO: enum? one case is "normal"
            public let voltage: Double
        }

        public struct State {
            public let stateDescription: String // TODO: enum? one case is "normal"
            public let isBolusing: Bool
            public let isSuspended: Bool
            public let timestamp: Date
        }

        public let clockDate: Date
        public let reservoirInsulinRemaining: Double
        public let battery: Battery
        public let state: State?
    }

    public struct UploaderStatus {
        public let batteryVoltage: Int
        public let batteryPercentage: Int
    }

    public let closedLoopStatus: ClosedLoopStatus
    public let pumpStatus: PumpStatus
    public let uploaderStatus: UploaderStatus
}

// MARK: - JSON

extension OpenAPSDeviceStatus: JSONParseable {
    typealias JSONParseType = JSONDictionary

    private enum Key {
        static let closedLoopStatus: JSONKey<ClosedLoopStatus> = "openaps"
        static let pumpStatus: JSONKey<PumpStatus> = "pump"
        static let uploaderStatus: JSONKey<UploaderStatus> = "uploader"
    }

    static func parse(fromJSON deviceStatusJSON: JSONDictionary) -> OpenAPSDeviceStatus? {
        guard
            let closedLoopStatus = deviceStatusJSON[parsingFrom: Key.closedLoopStatus],
            let pumpStatus = deviceStatusJSON[parsingFrom: Key.pumpStatus],
            let uploaderStatus = deviceStatusJSON[parsingFrom: Key.uploaderStatus]
        else {
            return nil
        }

        return .init(closedLoopStatus: closedLoopStatus, pumpStatus: pumpStatus, uploaderStatus: uploaderStatus)
    }
}

extension OpenAPSDeviceStatus.ClosedLoopStatus: JSONParseable {
    typealias JSONParseType = JSONDictionary

    private enum Key {
        static let activeInsulinContext: JSONKey<ActiveInsulinContext> = "iob"
        static let suggested: JSONKey<Context> = "suggested"
        static let enacted: JSONKey<Context> = "enacted"
    }

    static func parse(fromJSON json: JSONDictionary) -> OpenAPSDeviceStatus.ClosedLoopStatus? {
        guard
            let suggested = json[parsingFrom: Key.suggested],
            let enacted = json[parsingFrom: Key.enacted]
        else {
            return nil
        }

        return .init(
            activeInsulinContext: json[parsingFrom: Key.activeInsulinContext],
            suggested: suggested,
            enacted: enacted
        )
    }
}

extension OpenAPSDeviceStatus.ClosedLoopStatus.ActiveInsulinContext: JSONParseable {
    typealias JSONParseType = JSONDictionary

    private enum Key {
        static let insulinOnBoard: JSONKey<Double> = "iob"
        static let recentInsulinActivity: JSONKey<Double> = "activity"
        static let basalInsulinOnBoard: JSONKey<Double> = "basaliob"
        static let bolusInsulinOnBoard: JSONKey<Double> = "bolusiob"
        static let lastTemporaryBasal: JSONKey<OpenAPSDeviceStatus.ClosedLoopStatus.TemporaryBasal> = "lastTemp"
        static let timestampString: JSONKey<String> = "timestamp"
    }

    static func parse(fromJSON json: JSONDictionary) -> OpenAPSDeviceStatus.ClosedLoopStatus.ActiveInsulinContext? {
        guard
            let insulinOnBoard = json[Key.insulinOnBoard],
            let recentInsulinActivity = json[Key.recentInsulinActivity],
            let basalInsulinOnBoard = json[Key.basalInsulinOnBoard],
            let bolusInsulinOnBoard = json[Key.bolusInsulinOnBoard],
            let lastBolus = OpenAPSDeviceStatus.ClosedLoopStatus.Bolus.parse(fromJSON: json),
            let lastTemporaryBasal = json[parsingFrom: Key.lastTemporaryBasal],
            let timestamp = json[convertingDateFrom: Key.timestampString]
        else {
            return nil
        }

        return .init(
            insulinOnBoard: insulinOnBoard,
            recentInsulinActivity: recentInsulinActivity,
            basalInsulinOnBoard: basalInsulinOnBoard,
            bolusInsulinOnBoard: bolusInsulinOnBoard,
            lastBolus: lastBolus,
            lastTemporaryBasal: lastTemporaryBasal,
            timestamp: timestamp
        )
    }
}

extension OpenAPSDeviceStatus.ClosedLoopStatus.Bolus: JSONParseable {
    typealias JSONParseType = JSONDictionary

    private enum Key {
        static let amount: JSONKey<Double> = "bolusinsulin"
        static let date: JSONKey<Int> = "lastBolusTime"
    }

    static func parse(fromJSON json: JSONDictionary) -> OpenAPSDeviceStatus.ClosedLoopStatus.Bolus? {
        guard
            let amount = json[Key.amount],
            let date = json[Key.date].map(TimeInterval.init).map(Date.init(timeIntervalSince1970:))
        else {
            return nil
        }

        return .init(amount: amount, date: date)
    }
}

extension OpenAPSDeviceStatus.ClosedLoopStatus.TemporaryBasal: JSONParseable {
    typealias JSONParseType = JSONDictionary

    private enum Key {
        static let rate: JSONKey<Double> = "rate"
        static let startDateString: JSONKey<String> = "started_at"
        static let durationInMinutes: JSONKey<Double> = "duration"
    }

    fileprivate static func parse(fromJSON json: JSONDictionary, withDateStringKey dateStringKey: JSONKey<String>) -> OpenAPSDeviceStatus.ClosedLoopStatus.TemporaryBasal? {
        guard
            let rate = json[Key.rate],
            let startDate = json[convertingDateFrom: dateStringKey],
            let duration = json[Key.durationInMinutes].map(TimeInterval.init(minutes:))
        else {
            return nil
        }

        return .init(rate: rate, startDate: startDate, duration: duration)
    }

    static func parse(fromJSON json: JSONDictionary) -> OpenAPSDeviceStatus.ClosedLoopStatus.TemporaryBasal? {
        return parse(fromJSON: json, withDateStringKey: Key.startDateString)
    }
}

extension OpenAPSDeviceStatus.ClosedLoopStatus.Context: JSONParseable {
    typealias JSONParseType = JSONDictionary

    private enum Key {
        static let reason: JSONKey<String> = "reason"
        static let timestampString: JSONKey<String> = "timestamp"
    }

    static func parse(fromJSON json: JSONDictionary) -> OpenAPSDeviceStatus.ClosedLoopStatus.Context? {
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

extension OpenAPSDeviceStatus.ClosedLoopStatus.Context.State: JSONParseable {
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

    static func parse(fromJSON json: JSONDictionary) -> OpenAPSDeviceStatus.ClosedLoopStatus.Context.State? {
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
            temporaryBasal: OpenAPSDeviceStatus.ClosedLoopStatus.TemporaryBasal.parse(fromJSON: json, withDateStringKey: Key.deliveryDateString),
            received: json[Key.received] ?? false,
            sensitivityRatio: sensitivityRatio,
            predictedBloodGlucoseValues: json[parsingFrom: Key.predictedBloodGlucoseValuesJSON],
            carbsOnBoard: carbsOnBoard,
            insulinOnBoard: insulinOnBoard
        )
    }
}

extension OpenAPSDeviceStatus.ClosedLoopStatus.Context.State.PredictedBloodGlucoseValues: JSONParseable {
    typealias JSONParseType = JSONDictionary

    private enum Key {
        static let basedOnInsulinOnBoard: JSONKey<[Int]> = "IOB"
        static let withZeroBasal: JSONKey<[Int]> = "ZT"
        static let basedOnCarbAbsorption: JSONKey<[Int]> = "COB"
    }

    static func parse(fromJSON json: JSONDictionary) -> OpenAPSDeviceStatus.ClosedLoopStatus.Context.State.PredictedBloodGlucoseValues? {
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
        static let battery: JSONKey<Battery> = "battery"
        static let reservoirInsulinRemaining: JSONKey<Double> = "reservoir"
        static let state: JSONKey<State> = "status"
    }

    static func parse(fromJSON json: JSONDictionary) -> OpenAPSDeviceStatus.PumpStatus? {
        guard
            let clockDate = json[convertingDateFrom: Key.clockDateString],
            let battery = json[parsingFrom: Key.battery],
            let reservoirInsulinRemaining = json[Key.reservoirInsulinRemaining]
        else {
            return nil
        }

        return .init(
            clockDate: clockDate,
            reservoirInsulinRemaining: reservoirInsulinRemaining,
            battery: battery,
            state: json[parsingFrom: Key.state]
        )
    }
}

extension OpenAPSDeviceStatus.PumpStatus.Battery: JSONParseable {
    typealias JSONParseType = JSONDictionary

    private enum Key {
        static let status: JSONKey<String> = "status"
        static let voltage: JSONKey<Double> = "voltage"
    }

    static func parse(fromJSON json: JSONDictionary) -> OpenAPSDeviceStatus.PumpStatus.Battery? {
        guard
            let status = json[Key.status],
            let voltage = json[Key.voltage]
        else {
            return nil
        }

        return .init(status: status, voltage: voltage)
    }
}

extension OpenAPSDeviceStatus.PumpStatus.State: JSONParseable {
    typealias JSONParseType = JSONDictionary

    private enum Key {
        static let stateDescription: JSONKey<String> = "status"
        static let isBolusing: JSONKey<Bool> = "bolusing"
        static let isSuspended: JSONKey<Bool> = "suspended"
        static let timestampString: JSONKey<String> = "timestamp"
    }

    static func parse(fromJSON json: JSONDictionary) -> OpenAPSDeviceStatus.PumpStatus.State? {
        guard
            let stateDescription = json[Key.stateDescription],
            let isBolusing = json[Key.isBolusing],
            let isSuspended = json[Key.isSuspended],
            let timestamp = json[convertingDateFrom: Key.timestampString]
        else {
            return nil
        }

        return .init(stateDescription: stateDescription, isBolusing: isBolusing, isSuspended: isSuspended, timestamp: timestamp)
    }
}

extension OpenAPSDeviceStatus.UploaderStatus: JSONParseable {
    typealias JSONParseType = JSONDictionary

    private enum Key {
        static let batteryVoltage: JSONKey<Int> = "batteryVoltage"
        static let batteryPercentage: JSONKey<Int> = "battery"
    }

    static func parse(fromJSON json: JSONDictionary) -> OpenAPSDeviceStatus.UploaderStatus? {
        guard
            let batteryVoltage = json[Key.batteryVoltage],
            let batteryPercentage = json[Key.batteryPercentage]
        else {
            return nil
        }

        return .init(batteryVoltage: batteryVoltage, batteryPercentage: batteryPercentage)
    }
}

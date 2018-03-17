//
//  OpenAPSDeviceStatus.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 3/8/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

public struct OpenAPSDeviceStatus {
    /// Describes the status of an OpenAPS closed loop.
    public struct LoopStatus: ClosedLoopStatusProtocol {
        /// Describes a bolus.
        public struct Bolus {
            /// The amount of insulin delivered in units (U).
            public let amount: Double

            /// The date at which the bolus was delivered.
            public let date: Date
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

        /// Describes the status of insulin on board.
        public struct InsulinOnBoardStatus: InsulinOnBoardStatusProtocol {
            /// The total insulin on board in units (U),
            /// equal to the sum of the basal and bolus insulin on board.
            public let insulinOnBoard: Double?

            /// The recent activity of insulin.
            /// Equal to (net insulin on board 1 minute ago) - (net insulin on board now).
            public let recentInsulinActivity: Double

            /// The basal insulin on board in units (U).
            public let basalInsulinOnBoard: Double?

            /// The bolus insulin on board in units (U).
            public let bolusInsulinOnBoard: Double?

            /// The last bolus delivered.
            public let lastBolus: Bolus

            /// The last temporary basal enacted.
            public let lastTemporaryBasal: TemporaryBasal

            /// The date at which the status of the insulin on board was recorded.
            public let timestamp: Date
        }

        /// Describes the context of an OpenAPS closed loop.
        public struct Context {
            /// Describes the state of an OpenAPS closed loop.
            public struct State {
                /// Describes the predicted glucose values based on the state of the closed loop.
                public struct PredictedBloodGlucoseCurves {
                    /// The predicted glucose values based only on the insulin on board.
                    /// The first member represents the predicted glucose value at the start date,
                    /// and each subsequent member represents the predicted glucose five minutes after the previous.
                    public let basedOnInsulinOnBoard: [Int]

                    /// The predicted glucose values if a temporary basal with a rate of zero were set and held.
                    /// The first member represents the predicted glucose value at the start date,
                    /// and each subsequent member represents the predicted glucose five minutes after the previous.
                    public let withZeroBasal: [Int]

                    /// The predicted glucose values based on the current carb absorption and insulin on board.
                    /// The first member represents the predicted glucose value at the start date,
                    /// and each subsequent member represents the predicted glucose five minutes after the previous.
                    public let basedOnCarbAbsorption: [Int]?

                    /// The predicted glucose values based on an unannounced meal.
                    /// The first member represents the predicted glucose value at the start date,
                    /// and each subsequent member represents the predicted glucose five minutes after the previous.
                    public let basedOnUnannouncedMeal: [Int]?

                    /// An array containing all of the blood glucose prediction curves.
                    /// Within each prediction curve, the first member represents the predicted glucose value at the start date,
                    /// and each subsequent member represents the predicted glucose five minutes after the previous.
                    public var all: [[Int]] {
                        return [basedOnInsulinOnBoard,
                                withZeroBasal, basedOnCarbAbsorption, basedOnUnannouncedMeal].flatMap { $0 }
                    }
                }

                /// The blood glucose value at the date the state was recorded.
                public let bloodGlucoseValue: Int

                /// The change in blood glucose value since the last recorded blood glucose value.
                public let deltaFromLastBloodGlucoseValue: Int

                /// The predicted eventual blood glucose value based on the state of the closed loop.
                public let predictedEventualBloodGlucoseValue: Int

                /// The temporary basal in effect.
                public let temporaryBasal: TemporaryBasal?

                /// A boolean value describing whether the temporary basal was received by the pump.
                public let received: Bool

                /// The sensitivity ratio in effect in grams per unit (g/U).
                public let sensitivityRatio: Double

                /// The predicted blood glucose values based on the state of the closed loop.
                public let predictedBloodGlucoseCurves: PredictedBloodGlucoseCurves?

                /// The carbs on board in grams (g).
                public let carbsOnBoard: Int

                /// The insulin on board in units (U).
                public let insulinOnBoard: Double
            }

            /// The state of the closed loop.
            public let state: State?

            /// The reason for the closed loop action described by the state.
            public let reason: String

            /// The date at which the closed loop context was enacted or is expected.
            public let timestamp: Date

            /// The predicted blood glucose curves based on the state of the closed loop.
            public var predictedBloodGlucoseCurves: [[PredictedBloodGlucoseValue]]? {
                return state?.predictedBloodGlucoseCurves?.all.map {
                    Array<PredictedBloodGlucoseValue>(values: $0, everyFiveMinutesBeginningAt: timestamp)
                }
            }
        }

        /// The status of the insulin on board (IOB).
        public let insulinOnBoardStatus: InsulinOnBoardStatus?

        /// The suggested closed loop context to take effect.
        public let suggested: Context

        /// The enacted closed loop context.
        public let enacted: Context

        /// The date at which the closed loop status was recorded.
        public var timestamp: Date {
            return enacted.timestamp
        }

        /// The carbs on board in grams (g).
        public var carbsOnBoard: Int? {
            return enacted.state?.carbsOnBoard
        }

        /// The enacted temporary basal.
        public var enactedTemporaryBasal: TemporaryBasal? {
            return enacted.state?.temporaryBasal
        }

        /// The temporary basal recommended by the loop.
        public var recommendedTemporaryBasal: TemporaryBasal? {
            return suggested.state?.temporaryBasal
        }

        /// An array of predicted glucose value curves based on currently available data.
        public var predictedBloodGlucoseCurves: [[PredictedBloodGlucoseValue]]? {
            return enacted.predictedBloodGlucoseCurves ?? suggested.predictedBloodGlucoseCurves
        }
    }

    /// Describes the status of the insulin pump in communication with OpenAPS.
    public struct PumpStatus: PumpStatusProtocol {
        /// Describes the battery status of the pump.
        public struct BatteryStatus: BatteryStatusProtocol {
            /// The status of the battery.
            public let status: BatteryIndicator?

            /// The voltage of the battery.
            public let voltage: Double?
        }

        /// The date of the pump clock.
        public let clockDate: Date

        /// The reservoir insulin remaining in units (U).
        public let reservoirInsulinRemaining: Double?

        /// The status of the pump battery.
        public let batteryStatus: BatteryStatus?

        /// A string describing the status of the pump.
        public let statusDescription: String? // TODO: enum? one case is "normal"

        /// A boolean value representing whether the pump is currently bolusing.
        public let isBolusing: Bool?

        /// A boolean value representing whether the pump is currently suspended.
        public let isSuspended: Bool?

        /// The date at which the pump status was recorded.
        public let timestamp: Date?
    }

    /// Describes the status of the device uploading OpenAPS data to Nightscout.
    public struct UploaderStatus: UploaderStatusProtocol {
        /// The voltage of the battery of the uploading device.
        public let batteryVoltage: Int

        /// The percentage of battery remaining of the uploading device.
        public let batteryPercentage: Int?
    }

    /// The status of the closed loop.
    public let loopStatus: LoopStatus

    /// The status of the insulin pump used in the loop.
    public let pumpStatus: PumpStatus

    /// The status of the device uploading the loop status.
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
        static let predictedBloodGlucoseCurves: JSONKey<PredictedBloodGlucoseCurves> = "predBGs"
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
            predictedBloodGlucoseCurves: json[parsingFrom: Key.predictedBloodGlucoseCurves],
            carbsOnBoard: carbsOnBoard,
            insulinOnBoard: insulinOnBoard
        )
    }
}

extension OpenAPSDeviceStatus.LoopStatus.Context.State.PredictedBloodGlucoseCurves: JSONParseable {
    typealias JSONParseType = JSONDictionary

    private enum Key {
        static let basedOnInsulinOnBoard: JSONKey<[Int]> = "IOB"
        static let withZeroBasal: JSONKey<[Int]> = "ZT"
        static let basedOnCarbAbsorption: JSONKey<[Int]> = "COB"
        static let basedOnUnannouncedMeal: JSONKey<[Int]> = "UAM"
    }

    static func parse(fromJSON json: JSONDictionary) -> OpenAPSDeviceStatus.LoopStatus.Context.State.PredictedBloodGlucoseCurves? {
        guard
            let basedOnInsulinOnBoard = json[Key.basedOnInsulinOnBoard],
            let withZeroBasal = json[Key.withZeroBasal]
        else {
            return nil
        }

        return .init(
            basedOnInsulinOnBoard: basedOnInsulinOnBoard,
            withZeroBasal: withZeroBasal,
            basedOnCarbAbsorption: json[Key.basedOnCarbAbsorption],
            basedOnUnannouncedMeal: json[Key.basedOnUnannouncedMeal]
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
        static let statusDescription: JSONKey<String> = "status"
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
            statusDescription: statusJSON?[Key.statusDescription],
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

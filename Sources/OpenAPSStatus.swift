//
//  OpenAPSStatus.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 3/8/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

// TODO: heavy renaming in here for Swift conventions
public struct OpenAPSStatus {
    struct ClosedLoopStatus {
        struct InsulinOnBoard {
            struct WithZeroTemp {
                let insulinOnBoard: Double
                let activity: Double
                let basalInsulinOnBoard: Double
                let bolusInsulinOnBoard: Double
                let netBasalInsulin: Double
                let bolusInsulin: Double
                let date: Date
            }

            let insulinOnBoard: Double
            let activity: Double
            let basalInsulinOnBoard: Double
            let bolusInsulinOnBoard: Double
            let netBasalInsulin: Double
            let bolusInsulin: Double
            let withZeroTemp: WithZeroTemp
            let lastBolusDate: Date
            let lastTemporaryBasal: TemporaryBasal
            let timestamp: Date
        }

        struct TemporaryBasal {
            let rate: Double
            let timestamp: Date // TODO: what is the significance of timestamp vs. start date?
            let startDate: Date
            let duration: Double
        }

        struct Suggested {
            struct PredictedBloodGlucoseValues {
                let insulinOnBoard: [Int]
                let zt: [Int] // ??
                let carbsOnBoard: [Int]?
            }

            let temporaryBasal: String // TODO: probably an enum--one possible value is "absolute"
            let bloodGlucoseValue: Int
            let tick: Int // ??
            let eventualBloodGlucoseValue: Int
            let insulinRequired: Double
            let reservoir: Double // keyed as a String, likely reservoir remaining?
            let deliveryDate: Date
            let sensitivityRatio: Double
            let predictedBloodGlucoseValues: PredictedBloodGlucoseValues?
            let carbsOnBoard: Int
            let insulinOnBoard: Double
            let reason: String
            let timestamp: Date
        }

        struct Enacted {
            let insulinRequired: Double
            let bloodGlucoseValue: Int
            let reservoir: Double // see above note
            let temporaryBasal: String // see above note
            let rate: Double
            let reason: String
            let insulinOnBoard: Double
            let sensitivityRatio: Double
            let carbsOnBoard: Int
            let eventualBloodGlucoseValue: Int
            let received: Bool
            let duration: TimeInterval // stored as minutes
            let tick: Int
            let timestamp: Date
            let deliveryDate: Date
        }

        let insulinOnBoard: InsulinOnBoard
        let suggested: Suggested
        let enacted: Enacted
    }

    struct Pump {
        struct Battery {
            let status: String // enum? one case "normal"
            let voltage: Double
        }

        struct Status {
            let state: String // key is "status", probably an enum (one case is "normal")
            let isBolusing: Bool
            let isSuspended: Bool
            let timestamp: Date
        }

        let clock: Date // can't tell if this is stored as ISO8601 or something else
        let reservoir: Double // not in a string, unlike above
        let battery: Battery
        let status: Status
    }

    struct Uploader {
        let batteryVoltage: Int
        let battery: Int // presumably percentage
    }

    let closedLoopStatus: ClosedLoopStatus
    let pumpStatus: Pump
    let uploaderStatus: Uploader
}

// MARK: - JSON

extension OpenAPSStatus: JSONParseable {
    typealias JSONParseType = JSONDictionary

    private enum Key {
        static let closedLoop: JSONKey<JSONDictionary> = "openaps"
        static let pump: JSONKey<JSONDictionary> = "pump"
        static let uploader: JSONKey<JSONDictionary> = "uploader"
    }

    static func parse(fromJSON deviceStatusJSON: JSONDictionary) -> OpenAPSStatus? {
        guard
            let closedLoopStatus = deviceStatusJSON[Key.closedLoop].flatMap(ClosedLoopStatus.parse(fromJSON:)),
            let pump = deviceStatusJSON[Key.pump].flatMap(Pump.parse(fromJSON:)),
            let uploader = deviceStatusJSON[Key.uploader].flatMap(Uploader.parse(fromJSON:))
        else {
            return nil
        }

        return .init(closedLoopStatus: closedLoopStatus, pumpStatus: pump, uploaderStatus: uploader)
    }
}

extension OpenAPSStatus.ClosedLoopStatus: JSONParseable {
    typealias JSONParseType = JSONDictionary

    private enum Key {
        static let insulinOnBoard: JSONKey<JSONDictionary> = "iob"
        static let suggested: JSONKey<JSONDictionary> = "suggested"
        static let enacted: JSONKey<JSONDictionary> = "enacted"
    }

    static func parse(fromJSON json: JSONDictionary) -> OpenAPSStatus.ClosedLoopStatus? {
        guard
            let insulinOnboard = json[Key.insulinOnBoard].flatMap(InsulinOnBoard.parse(fromJSON:)),
            let suggested = json[Key.suggested].flatMap(Suggested.parse(fromJSON:)),
            let enacted = json[Key.enacted].flatMap(Enacted.parse(fromJSON:))
        else {
            return nil
        }

        return .init(insulinOnBoard: insulinOnboard, suggested: suggested, enacted: enacted)
    }
}

extension OpenAPSStatus.ClosedLoopStatus.InsulinOnBoard: JSONParseable {
    typealias JSONParseType = JSONDictionary

    private enum Key {
        static let insulinOnBoard: JSONKey<Double> = "iob"
        static let activity: JSONKey<Double> = "activity"
        static let basalInsulinOnBoard: JSONKey<Double> = "basaliob"
        static let bolusInsulinOnBoard: JSONKey<Double> = "bolusiob"
        static let netBasalInsulin: JSONKey<Double> = "netbasalinsulin"
        static let bolusInsulin: JSONKey<Double> = "bolusinsulin"
        static let withZeroTemp: JSONKey<JSONDictionary> = "iobWithZeroTemp"
        static let lastBolusTime: JSONKey<Int> = "lastBolusTime"
        static let lastTemporaryBasal: JSONKey<JSONDictionary> = "lastTemp"
        static let timestamp: JSONKey<String> = "timestamp"
    }

    static func parse(fromJSON json: JSONDictionary) -> OpenAPSStatus.ClosedLoopStatus.InsulinOnBoard? {
        guard
            let insulinOnBoard = json[Key.insulinOnBoard],
            let activity = json[Key.activity],
            let basalInsulinOnBoard = json[Key.basalInsulinOnBoard],
            let bolusInsulinOnBoard = json[Key.bolusInsulinOnBoard],
            let netBasalInsulin = json[Key.netBasalInsulin],
            let bolusInsulin = json[Key.bolusInsulin],
            let withZeroTemp = json[Key.withZeroTemp].flatMap(WithZeroTemp.parse(fromJSON:)),
            let lastBolusDate = json[Key.lastBolusTime].map(TimeInterval.init).map(Date.init(timeIntervalSince1970:)),
            let lastTemporaryBasal = json[Key.lastTemporaryBasal].flatMap(OpenAPSStatus.ClosedLoopStatus.TemporaryBasal.parse(fromJSON:)),
            let timestamp = json[Key.timestamp].flatMap(TimeFormatter.date(from:))
        else {
            return nil
        }

        return .init(insulinOnBoard: insulinOnBoard, activity: activity, basalInsulinOnBoard: basalInsulinOnBoard, bolusInsulinOnBoard: bolusInsulinOnBoard, netBasalInsulin: netBasalInsulin, bolusInsulin: bolusInsulin, withZeroTemp: withZeroTemp, lastBolusDate: lastBolusDate, lastTemporaryBasal: lastTemporaryBasal, timestamp: timestamp)
    }
}

extension OpenAPSStatus.ClosedLoopStatus.InsulinOnBoard.WithZeroTemp: JSONParseable {
    typealias JSONParseType = JSONDictionary

    private enum Key {
        static let insulinOnBoard: JSONKey<Double> = "iob"
        static let activity: JSONKey<Double> = "activity"
        static let basalInsulinOnBoard: JSONKey<Double> = "basaliob"
        static let bolusInsulinOnBoard: JSONKey<Double> = "bolusiob"
        static let netBasalInsulin: JSONKey<Double> = "netbasalinsulin"
        static let bolusInsulin: JSONKey<Double> = "bolusinsulin"
        static let date: JSONKey<String> = "time"
    }

    static func parse(fromJSON json: JSONDictionary) -> OpenAPSStatus.ClosedLoopStatus.InsulinOnBoard.WithZeroTemp? {
        guard
            let insulinOnBoard = json[Key.insulinOnBoard],
            let activity = json[Key.activity],
            let basalInsulinOnBoard = json[Key.basalInsulinOnBoard],
            let bolusInsulinOnBoard = json[Key.bolusInsulinOnBoard],
            let netBasalInsulin = json[Key.netBasalInsulin],
            let bolusInsulin = json[Key.bolusInsulin],
            let date = json[Key.date].flatMap(TimeFormatter.date(from:))
        else {
            return nil
        }

        return .init(insulinOnBoard: insulinOnBoard, activity: activity, basalInsulinOnBoard: basalInsulinOnBoard, bolusInsulinOnBoard: bolusInsulinOnBoard, netBasalInsulin: netBasalInsulin, bolusInsulin: bolusInsulin, date: date)
    }
}

extension OpenAPSStatus.ClosedLoopStatus.TemporaryBasal: JSONParseable {
    typealias JSONParseType = JSONDictionary

    private enum Key {
        static let rate: JSONKey<Double> = "rate"
        static let timestamp: JSONKey<String> = "timestamp"
        static let startDateString: JSONKey<String> = "started_at"
        static let date: JSONKey<Int> = "date" // TODO: do we need this as well as timestamp and start date?
        static let duration: JSONKey<Double> = "duration"

    }

    static func parse(fromJSON json: JSONDictionary) -> OpenAPSStatus.ClosedLoopStatus.TemporaryBasal? {
        guard
            let rate = json[Key.rate],
            let timestamp = json[Key.timestamp].flatMap(TimeFormatter.date(from:)),
            let startDate = json[Key.startDateString].flatMap(TimeFormatter.date(from:)),
            let duration = json[Key.duration]
        else {
            return nil
        }

        return .init(rate: rate, timestamp: timestamp, startDate: startDate, duration: duration)
    }
}

extension OpenAPSStatus.ClosedLoopStatus.Suggested: JSONParseable {
    typealias JSONParseType = JSONDictionary

    private enum Key {
        static let temporaryBasal: JSONKey<String> = "temp"
        static let bloodGlucoseValue: JSONKey<Int> = "bg"
        static let tick: JSONKey<Int> = "tick"
        static let eventualBloodGlucoseValue: JSONKey<Int> = "eventualBG"
        static let insulinRequired: JSONKey<Double> = "insulinReq"
        static let reservoirString: JSONKey<String> = "reservoir"
        static let deliveryDateString: JSONKey<String> = "deliverAt"
        static let sensitivityRatio: JSONKey<Double> = "sensitivityRatio"
        static let predictedBloodGlucoseValues: JSONKey<JSONDictionary> = "predBGs"
        static let carbsOnBoard: JSONKey<Int> = "COB"
        static let insulinOnBoard: JSONKey<Double> = "IOB"
        static let reason: JSONKey<String> = "reason"
        static let timestamp: JSONKey<String> = "timestamp"
    }

    static func parse(fromJSON json: JSONDictionary) -> OpenAPSStatus.ClosedLoopStatus.Suggested? {
        guard
            let temporaryBasal = json[Key.temporaryBasal],
            let bloodGlucoseValue = json[Key.bloodGlucoseValue],
            let tick = json[Key.tick],
            let eventualBloodGlucoseValue = json[Key.eventualBloodGlucoseValue],
            let insulinRequired = json[Key.insulinRequired],
            let reservoir = json[Key.reservoirString].flatMap(Double.init),
            let deliveryDate = json[Key.deliveryDateString].flatMap(TimeFormatter.date(from:)),
            let sensitivityRatio = json[Key.sensitivityRatio],
            let carbsOnBoard = json[Key.carbsOnBoard],
            let insulinOnBoard = json[Key.insulinOnBoard],
            let reason = json[Key.reason],
            let timestamp = json[Key.timestamp].flatMap(TimeFormatter.date(from:))
        else {
            return nil
        }

        return .init(
            temporaryBasal: temporaryBasal,
            bloodGlucoseValue: bloodGlucoseValue,
            tick: tick,
            eventualBloodGlucoseValue: eventualBloodGlucoseValue,
            insulinRequired: insulinRequired,
            reservoir: reservoir,
            deliveryDate: deliveryDate,
            sensitivityRatio: sensitivityRatio,
            predictedBloodGlucoseValues: json[Key.predictedBloodGlucoseValues].flatMap(PredictedBloodGlucoseValues.parse(fromJSON:)),
            carbsOnBoard: carbsOnBoard,
            insulinOnBoard: insulinOnBoard,
            reason: reason,
            timestamp: timestamp
        )
    }
}

extension OpenAPSStatus.ClosedLoopStatus.Suggested.PredictedBloodGlucoseValues: JSONParseable {
    typealias JSONParseType = JSONDictionary

    private enum Key {
        static let insulinOnBoard: JSONKey<[Int]> = "IOB"
        static let zt: JSONKey<[Int]> = "ZT"
        static let carbsOnBoard: JSONKey<[Int]> = "COB"
    }

    static func parse(fromJSON json: JSONDictionary) -> OpenAPSStatus.ClosedLoopStatus.Suggested.PredictedBloodGlucoseValues? {
        guard
            let insulinOnBoard = json[Key.insulinOnBoard],
            let zt = json[Key.zt]
        else {
            return nil
        }

        return .init(
            insulinOnBoard: insulinOnBoard,
            zt: zt,
            carbsOnBoard: json[Key.carbsOnBoard]
        )
    }
}

extension OpenAPSStatus.ClosedLoopStatus.Enacted: JSONParseable {
    typealias JSONParseType = JSONDictionary

    private enum Key {
        static let temporaryBasal: JSONKey<String> = "temp"
        static let rate: JSONKey<Double> = "rate"
        static let received: JSONKey<Bool> = "recieved" // yes, "received" really is misspelled
        static let durationInMinutes: JSONKey<Int> = "duration"
        static let bloodGlucoseValue: JSONKey<Int> = "bg"
        static let tick: JSONKey<Int> = "tick"
        static let eventualBloodGlucoseValue: JSONKey<Int> = "eventualBG"
        static let insulinRequired: JSONKey<Double> = "insulinReq"
        static let reservoirString: JSONKey<String> = "reservoir"
        static let deliveryDate: JSONKey<String> = "deliverAt"
        static let sensitivityRatio: JSONKey<Double> = "sensitivityRatio"
        static let carbsOnBoard: JSONKey<Int> = "COB"
        static let insulinOnBoard: JSONKey<Double> = "IOB"
        static let reason: JSONKey<String> = "reason"
        static let timestamp: JSONKey<String> = "timestamp"
    }

    static func parse(fromJSON json: JSONDictionary) -> OpenAPSStatus.ClosedLoopStatus.Enacted? {
        guard
            let temporaryBasal = json[Key.temporaryBasal],
            let rate = json[Key.rate],
            let received = json[Key.received],
            let duration = json[Key.durationInMinutes].map(Double.init).map(TimeInterval.init(minutes:)),
            let bloodGlucoseValue = json[Key.bloodGlucoseValue],
            let tick = json[Key.tick],
            let eventualBloodGlucoseValue = json[Key.eventualBloodGlucoseValue],
            let insulinRequired = json[Key.insulinRequired],
            let reservoir = json[Key.reservoirString].flatMap(Double.init),
            let deliveryDate = json[Key.deliveryDate].flatMap(TimeFormatter.date(from:)),
            let sensitivityRatio = json[Key.sensitivityRatio],
            let carbsOnBoard = json[Key.carbsOnBoard],
            let insulinOnBoard = json[Key.insulinOnBoard],
            let reason = json[Key.reason],
            let timestamp = json[Key.timestamp].flatMap(TimeFormatter.date(from:))
        else {
            return nil
        }

        return .init(insulinRequired: insulinRequired, bloodGlucoseValue: bloodGlucoseValue, reservoir: reservoir, temporaryBasal: temporaryBasal, rate: rate, reason: reason, insulinOnBoard: insulinOnBoard, sensitivityRatio: sensitivityRatio, carbsOnBoard: carbsOnBoard, eventualBloodGlucoseValue: eventualBloodGlucoseValue, received: received, duration: duration, tick: tick, timestamp: timestamp, deliveryDate: deliveryDate)
    }
}

extension OpenAPSStatus.Pump: JSONParseable {
    typealias JSONParseType = JSONDictionary

    private enum Key {
        static let clock: JSONKey<String> = "clock"
        static let battery: JSONKey<JSONDictionary> = "battery"
        static let reservoir: JSONKey<Double> = "reservoir"
        static let status: JSONKey<JSONDictionary> = "status"
    }

    static func parse(fromJSON json: JSONDictionary) -> OpenAPSStatus.Pump? {
        guard
            let clock = json[Key.clock].flatMap(TimeFormatter.date(from:)),
            let battery = json[Key.battery].flatMap(Battery.parse(fromJSON:)),
            let reservoir = json[Key.reservoir],
            let status = json[Key.status].flatMap(Status.parse(fromJSON:))
        else {
            return nil
        }

        return .init(clock: clock, reservoir: reservoir, battery: battery, status: status)
    }
}

extension OpenAPSStatus.Pump.Battery: JSONParseable {
    typealias JSONParseType = JSONDictionary

    private enum Key {
        static let status: JSONKey<String> = "status"
        static let voltage: JSONKey<Double> = "voltage"
    }

    static func parse(fromJSON json: JSONDictionary) -> OpenAPSStatus.Pump.Battery? {
        guard let status = json[Key.status], let voltage = json[Key.voltage] else {
            return nil
        }

        return .init(status: status, voltage: voltage)
    }
}

extension OpenAPSStatus.Pump.Status: JSONParseable {
    typealias JSONParseType = JSONDictionary

    private enum Key {
        static let status: JSONKey<String> = "status"
        static let isBolusing: JSONKey<Bool> = "bolusing"
        static let isSuspended: JSONKey<Bool> = "suspended"
        static let timestamp: JSONKey<String> = "timestamp"
    }

    static func parse(fromJSON json: JSONDictionary) -> OpenAPSStatus.Pump.Status? {
        guard
            let status = json[Key.status],
            let isBolusing = json[Key.isBolusing],
            let isSuspended = json[Key.isSuspended],
            let timestamp = json[Key.timestamp].flatMap(TimeFormatter.date(from:))
        else {
            return nil
        }

        return .init(state: status, isBolusing: isBolusing, isSuspended: isSuspended, timestamp: timestamp)
    }
}

extension OpenAPSStatus.Uploader: JSONParseable {
    typealias JSONParseType = JSONDictionary

    private enum Key {
        static let batteryVoltage: JSONKey<Int> = "batteryVoltage"
        static let battery: JSONKey<Int> = "battery"
    }

    static func parse(fromJSON json: JSONDictionary) -> OpenAPSStatus.Uploader? {
        guard let batteryVoltage = json[Key.batteryVoltage], let battery = json[Key.battery] else {
            return nil
        }

        return .init(batteryVoltage: batteryVoltage, battery: battery)
    }
}

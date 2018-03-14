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
    struct LoopStatus {
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

        struct RecommendedTemporaryBasal {

        }

        struct LoopEnacted {

        }

        struct RileyLinkStatus {

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

    }

    struct UploaderStatus {

    }

    struct RadioAdapter {

    }

    let loopStatus: LoopStatus
    let pumpStatus: PumpStatus
    let uploaderStatus: UploaderStatus
    let radioAdapter: RadioAdapter
}

// MARK: - JSON

extension LoopDeviceStatus: JSONParseable {
    typealias JSONParseType = JSONDictionary

    private enum Key {
        static let loopStatus: JSONKey<LoopStatus> = "loopStatus"
        static let pumpStatus: JSONKey<PumpStatus> = "pump"
        static let uploaderStatus: JSONKey<UploaderStatus> = "uploader"
        static let radioAdapter: JSONKey<RadioAdapter> = "radioAdapter"
    }

    static func parse(fromJSON json: JSONDictionary) -> LoopDeviceStatus? {
        fatalError()
    }
}

extension LoopDeviceStatus.LoopStatus: JSONParseable {
    typealias JSONParseType = JSONDictionary

    private enum Key {
        static let name: JSONKey<String> = "name"
        static let version: JSONKey<String> = "version"
        static let timestampString: JSONKey<String> = "timestamp"
        static let insulinOnBoardStatus: JSONKey<InsulinOnBoardStatus> = "iob"
        static let carbsOnBoardStatus: JSONKey<CarbsOnBoardStatus> = "cob"
        static let predictedBloodGlucoseValue: JSONKey<PredictedBloodGlucoseValues> = "predicted"
        static let recommendedTemporaryBasal: JSONKey<RecommendedTemporaryBasal> = "recommendedTempBasal"
        static let recommendedBolus: JSONKey<Double> = "recommendedBolus"
        static let loopEnacted: JSONKey<LoopEnacted> = "enacted"
        static let rileyLinkStatus: JSONKey<[RileyLinkStatus]> = "rileylinks"
        static let failureReason: JSONKey<String> = "failureReason"
    }

    static func parse(fromJSON json: JSONDictionary) -> LoopDeviceStatus.LoopStatus? {
        fatalError()
    }
}

extension LoopDeviceStatus.LoopStatus.InsulinOnBoardStatus: JSONParseable {
    typealias JSONParseType = JSONDictionary

    private enum Key {
        static let timestampString: JSONKey<String> = "timestamp"
        static let insulinOnBoard: JSONKey<Double> = "iob"
        static let basalInsulinOnBoard: JSONKey<Double> = "basaliob"
    }

    static func parse(fromJSON json: JSONDictionary) -> LoopDeviceStatus.LoopStatus.InsulinOnBoardStatus? {
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
        fatalError()
    }
}
















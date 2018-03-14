//
//  LoopDeviceStatus.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 3/13/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

struct LoopDeviceStatus {
    struct LoopStatus {

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

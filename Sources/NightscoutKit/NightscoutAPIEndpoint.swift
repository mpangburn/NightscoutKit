//
//  NightscoutAPIEndpoint.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 5/13/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Foundation


enum NightscoutAPIEndpoint: String {
    case entries = "entries"
    case treatments = "treatments"
    case profiles = "profile"
    case status = "status"
    case deviceStatus = "devicestatus"
    case authorization = "experiments/test"
}

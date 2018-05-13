//
//  Date.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 4/29/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Foundation


extension Date {
    var midnight: Date {
        let calendar = Calendar.current
        return calendar.startOfDay(for: self)
    }

    var timeIntervalSinceMidnight: TimeInterval {
        return timeIntervalSince(midnight)
    }
}

//
//  TimeInterval.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 2/18/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Foundation


extension TimeInterval {
    // MARK: - hours
    init(hours: Double) {
        self.init(minutes: hours * 60)
    }

    static func hours(_ hours: Double) -> TimeInterval {
        return self.init(hours: hours)
    }

    var hours: TimeInterval {
        return minutes / 60
    }
    
    // MARK: - minutes
    init(minutes: Double) {
        self.init(minutes * 60)
    }

    static func minutes(_ minutes: Double) -> TimeInterval {
        return self.init(minutes: minutes)
    }

    var minutes: Double {
        return self / 60
    }

    // MARK: - milliseconds
    init(milliseconds: Double) {
        self.init(milliseconds / 1000)
    }

    static func milliseconds(_ milliseconds: Double) -> TimeInterval {
        return self.init(milliseconds: milliseconds)
    }

    var milliseconds: Double {
        return self * 1000
    }
}

//
//  TimelineValue.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 3/24/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Foundation


/// A type that can be described by a date.
public protocol TimelineValue {
    /// The date of the timeline value.
    var date: Date { get }
}

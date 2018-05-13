//
//  Bolus.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 5/4/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Foundation


/// A bolus, i.e. an instance of insulin delivery.
public struct Bolus: TimelineValue, Hashable {
    /// The delivery date of the bolus.
    public let date: Date

    /// The total amount of insulin delivered in units (U).
    public let amount: Double

    /// Describes the context in which a bolus is delivered.
    public enum Context: String {
        case snack = "Snack Bolus"
        case meal = "Meal Bolus"
        case correction = "Correction Bolus"
    }

    /// The context in which the bolus is delivered.
    public let context: Context

    /// Creates a new bolus.
    /// - Parameter date: The delivery date of the bolus.
    /// - Parameter amount: The total amount of insulin delivered in units (U).
    /// - Parameter context: The context in which the bolus is delivered.
    /// - Returns: A new bolus.
    public init(date: Date, amount: Double, context: Context) {
        self.date = date
        self.amount = amount
        self.context = context
    }
}

// MARK: - JSON

extension Bolus: JSONParseable {
    private typealias Key = NightscoutTreatment.Key

    static func parse(fromJSON treatmentJSON: JSONDictionary) -> Bolus? {
        guard
            let context = treatmentJSON[Key.eventTypeString].flatMap(Context.init(rawValue:)),
            let date = treatmentJSON[convertingDateFrom: Key.dateString]
        else {
            return nil
        }

        let amount = treatmentJSON[Key.insulinGiven] ?? 0
        return .init(date: date, amount: amount, context: context)
    }
}

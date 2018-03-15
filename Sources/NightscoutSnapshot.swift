//
//  NightscoutSnapshot.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 3/1/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

/// A snapshot of a user's Nightscout data.
/// This type stores data such as recent blood glucose entries, treatments, profile records, and device statuses,
/// as well as the status of Nightscout site.
public struct NightscoutSnapshot {
    /// The date at which the snapshot was taken.
    public let timestamp: Date

    /// The status of the Nightscout site.
    public let status: NightscoutStatus

    /// An array containing the most recent entries at the snapshot date.
    public let entries: [NightscoutEntry]

    /// An array containing the most recent treatments at the snapshot date.
    public let treatments: [NightscoutTreatment]

    /// An array containing the profile records at the snapshot date.
    public let profileRecords: [NightscoutProfileRecord]

    /// An array containin the most recent device statuses at the snapshot date.
    public let deviceStatuses: [NightscoutDeviceStatus]
}

extension NightscoutSnapshot: CustomStringConvertible {
    public var description: String {
        return """
        ===== NIGHTSCOUT SNAPSHOT =====
        \(timestamp)

        ===== STATUS =====
        \(status)

        ===== ENTRIES =====
        \(entries.map(String.init(describing:)).joined(separator: "\n"))

        ===== TREATMENTS =====
        \(treatments.map(String.init(describing:)).joined(separator: "\n"))

        ===== PROFILE RECORDS =====
        \(profileRecords.map(String.init(describing:)).joined(separator: "\n"))
        
        ===== DEVICE STATUSES =====
        \(deviceStatuses.map(String.init(describing:)).joined(separator: "\n"))
        """
    }
}

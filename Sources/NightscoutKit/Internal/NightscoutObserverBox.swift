//
//  NightscoutObserverBox.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 3/24/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

/// A `NightscoutObserver` that forwards the protocol methods from its boxed observer, which is held weakly.
/// Since `NightscoutObserver` used as a type is not directly convertible to `AnyObject`,
/// we use this (safe) "hack" to store observers weakly in order to avoid retain cycles.
final class NightscoutObserverBox: _NightscoutObserver {
    private weak var _observer: AnyObject?

    var observer: NightscoutObserver? {
        if let observer = _observer {
            return observer as? NightscoutObserver // really should be `as!` but this produces a warning
        } else {
            return nil
        }
    }

    init(_ observer: NightscoutObserver) {
        self._observer = observer
    }

    override func nightscoutDidVerifyAuthorization(_ nightscout: Nightscout) {
        observer?.nightscoutDidVerifyAuthorization(nightscout)
    }

    override func nightscout(_ nightscout: Nightscout, didFetchStatus status: NightscoutStatus) {
        observer?.nightscout(nightscout, didFetchStatus: status)
    }

    override func nightscout(_ nightscout: Nightscout, didFetchEntries entries: [NightscoutEntry]) {
        observer?.nightscout(nightscout, didFetchEntries: entries)
    }

    override func nightscout(_ nightscout: Nightscout, didUploadEntries entries: Set<NightscoutEntry>) {
        observer?.nightscout(nightscout, didUploadEntries: entries)
    }

    override func nightscout(_ nightscout: Nightscout, didFailToUploadEntries entries: Set<NightscoutEntry>) {
        observer?.nightscout(nightscout, didFailToUploadEntries: entries)
    }

    override func nightscout(_ nightscout: Nightscout, didFetchTreatments treatments: [NightscoutTreatment]) {
        observer?.nightscout(nightscout, didFetchTreatments: treatments)
    }

    override func nightscout(_ nightscout: Nightscout, didUploadTreatments treatments: Set<NightscoutTreatment>) {
        observer?.nightscout(nightscout, didUploadTreatments: treatments)
    }

    override func nightscout(_ nightscout: Nightscout, didFailToUploadTreatments treatments: Set<NightscoutTreatment>) {
        observer?.nightscout(nightscout, didFailToUploadTreatments: treatments)
    }

    override func nightscout(_ nightscout: Nightscout, didUpdateTreatments treatments: Set<NightscoutTreatment>) {
        observer?.nightscout(nightscout, didUpdateTreatments: treatments)
    }

    override func nightscout(_ nightscout: Nightscout, didFailToUpdateTreatments treatments: Set<NightscoutTreatment>) {
        observer?.nightscout(nightscout, didFailToUpdateTreatments: treatments)
    }

    override func nightscout(_ nightscout: Nightscout, didDeleteTreatments treatments: Set<NightscoutTreatment>) {
        observer?.nightscout(nightscout, didDeleteTreatments: treatments)
    }

    override func nightscout(_ nightscout: Nightscout, didFailToDeleteTreatments treatments: Set<NightscoutTreatment>) {
        observer?.nightscout(nightscout, didFailToDeleteTreatments: treatments)
    }

    override func nightscout(_ nightscout: Nightscout, didFetchProfileRecords records: [NightscoutProfileRecord]) {
        observer?.nightscout(nightscout, didFetchProfileRecords: records)
    }

    override func nightscout(_ nightscout: Nightscout, didUploadProfileRecords records: Set<NightscoutProfileRecord>) {
        observer?.nightscout(nightscout, didUploadProfileRecords: records)
    }

    override func nightscout(_ nightscout: Nightscout, didFailToUploadProfileRecords records: Set<NightscoutProfileRecord>) {
        observer?.nightscout(nightscout, didFailToUploadProfileRecords: records)
    }

    override func nightscout(_ nightscout: Nightscout, didUpdateProfileRecords records: Set<NightscoutProfileRecord>) {
        observer?.nightscout(nightscout, didUpdateProfileRecords: records)
    }

    override func nightscout(_ nightscout: Nightscout, didFailToUpdateProfileRecords records: Set<NightscoutProfileRecord>) {
        observer?.nightscout(nightscout, didFailToUpdateProfileRecords: records)
    }

    override func nightscout(_ nightscout: Nightscout, didDeleteProfileRecords records: Set<NightscoutProfileRecord>) {
        observer?.nightscout(nightscout, didDeleteProfileRecords: records)
    }

    override func nightscout(_ nightscout: Nightscout, didFailToDeleteProfileRecords records: Set<NightscoutProfileRecord>) {
        observer?.nightscout(nightscout, didFailToDeleteProfileRecords: records)
    }

    override func nightscout(_ nightscout: Nightscout, didFetchDeviceStatuses deviceStatuses: [NightscoutDeviceStatus]) {
        observer?.nightscout(nightscout, didFetchDeviceStatuses: deviceStatuses)
    }

    override func nightscout(_ nightscout: Nightscout, didErrorWith error: NightscoutError) {
        observer?.nightscout(nightscout, didErrorWith: error)
    }
}

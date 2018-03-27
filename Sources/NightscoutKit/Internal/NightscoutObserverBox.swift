//
//  NightscoutObserverBox.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 3/24/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

/// Since `NightscoutObserver` used as a type is not directly convertible to `AnyObject`,
/// we use this "hack" to store observers weakly in order to avoid retain cycles.
/// This functionality could be generalized to some extent,
/// but this is basically a workaround for a `WeakBox<T: AnyObject>`
/// (which would not work in this situation for the reason described above).
final class NightscoutObserverBox {
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
}

//
//  NightscoutObserverBox.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 3/24/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

/// This box is a protocol equivalent for `WeakBox<T: AnyObject>`,
/// which we can't really generalize in these circumstances
/// since a protocol constrained to `AnyObject` is not directly convertible to `AnyObject`.
final class NightscoutObserverBox {
    private(set) weak var observer: NightscoutObserver?

    init(_ observer: NightscoutObserver) {
        self.observer = observer
    }
}

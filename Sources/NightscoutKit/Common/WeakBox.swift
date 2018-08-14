//
//  WeakBox.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 6/25/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

internal struct WeakBox<T> {
    private weak var _value: AnyObject?
    var value: T? {
        return _value as? T
    }

    init(_ value: T) {
        self._value = value as AnyObject
    }
}

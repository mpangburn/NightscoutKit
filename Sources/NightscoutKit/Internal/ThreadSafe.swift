//
//  ThreadSafe.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 3/23/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Foundation


// c.f. https://talk.objc.io/episodes/S01E90-concurrent-map
/// A class for ensuring safety in concurrently reading from or writing to a value.
final class ThreadSafe<Value> {
    private var _value: Value
    private let accessQueue = DispatchQueue(label: "com.mpangburn.nightscoutkit.threadsafe")

    init(_ value: Value) {
        self._value = value
    }

    var value: Value {
        return accessQueue.sync { _value }
    }

    func atomically(_ transform: (inout Value) -> Void) {
        accessQueue.sync { transform(&self._value) }
    }
}

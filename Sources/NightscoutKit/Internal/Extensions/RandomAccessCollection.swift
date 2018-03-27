//
//  RandomAccessCollection.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 3/26/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Dispatch


extension RandomAccessCollection {
    func concurrentForEach(_ body: (Element) -> Void) {
        DispatchQueue.concurrentPerform(iterations: numericCast(count)) { offset in
            let index = self.index(startIndex, offsetBy: numericCast(offset))
            let element = self[index]
            body(element)
        }
    }
}

//
//  Sequence.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 3/18/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

extension Sequence where SubSequence: Sequence, SubSequence.Element == Element {
    func adjacentPairs() -> [(Element, Element)] {
        // create an Array from dropFirst() because Sequence iteration can be destructive
        return Array(zip(self, Array(dropFirst())))
    }
}

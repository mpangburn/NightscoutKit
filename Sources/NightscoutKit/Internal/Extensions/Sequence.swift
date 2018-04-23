//
//  Sequence.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 3/18/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

extension Sequence where SubSequence: Sequence, SubSequence.Element == Element {
    /// - Warning: Behavior is undefined for single-pass sequences.
    func adjacentPairs() -> [(Element, Element)] {
        return Array(zip(self, dropFirst()))
    }
}

//
//  IdentifierFactory.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 3/14/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

enum IdentifierFactory {
    private static let idLength = 24
    private static let hexadecimalCharacters = Array("0123456789abcdef")

    static func makeID() -> String {
        return .randomString(ofLength: idLength, consistingOfCharactersIn: hexadecimalCharacters)
    }
}

fileprivate extension String {
    static func randomString<C: RandomAccessCollection>(ofLength length: Int, consistingOfCharactersIn characters: C) -> String where C.Element == Character, C.Index == Int {
        precondition(length >= 0 && characters.count > 0)
        return String((0..<length).map { _ in characters.random()! })
    }
}

fileprivate extension RandomAccessCollection where Index == Int {
    func random() -> Element? {
        guard !isEmpty else { return nil }
        let randomIndex = Int(arc4random_uniform(numericCast(count)))
        return self[randomIndex]
    }
}

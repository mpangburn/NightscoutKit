//
//  AnyJSON.swift
//  NightscoutKitTests
//
//  Created by Michael Pangburn on 3/6/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Foundation


/// A "type-erased" JSON wrapper to be used when the details of the response JSON are unknown.
struct AnyJSON {
    private let _json: Any

    init(_ json: Any) {
        self._json = json
    }
}

extension AnyJSON: JSONConvertible {
    typealias JSONParseType = Any

    static func parse(fromJSON json: Any) -> AnyJSON? {
        return AnyJSON(json)
    }

    func json() -> Any {
        return _json
    }
}

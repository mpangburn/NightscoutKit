//
//  String.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 3/3/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import CommonCrypto


extension String {
    func sha1() -> String {
        let data = self.data(using: .utf8)!
        var digest = Array<UInt8>(repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA1($0, CC_LONG(data.count), &digest)
        }
        let hexBytes = digest.map { String(format: "%02hhx", $0) }
        return hexBytes.joined()
    }
}

//
//  String.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 2/16/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

extension String {
    var capitalized: String {
        guard let first = first else {
            return ""
        }

        return String(first).uppercased() + String(dropFirst())
    }
}

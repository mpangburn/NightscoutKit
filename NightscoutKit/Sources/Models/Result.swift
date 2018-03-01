//
//  Result.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 2/18/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

enum Result<T> {
    case success(T)
    case failure(Error)
}

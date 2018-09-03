//
//  NightscoutResult.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 3/23/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Oxygen

/// Describes the result of a call to the Nightscout API.
public typealias NightscoutResult<Value> = Result<Value, NightscoutError>

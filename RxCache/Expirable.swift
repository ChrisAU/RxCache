//
//  Expirable.swift
//  RxCache
//
//  Created by Chris Nevin on 08/07/2017.
//  Copyright © 2017 Chris Nevin. All rights reserved.
//

import Foundation

public protocol Expirable {
    /// Check if the object has expired.
    var hasExpired: Bool { get }
}

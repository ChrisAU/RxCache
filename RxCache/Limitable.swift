//
//  Limitable.swift
//  RxCache
//
//  Created by Chris Nevin on 08/07/2017.
//  Copyright © 2017 Chris Nevin. All rights reserved.
//

import Foundation

public protocol Limitable {
    /// Maximum upper limit of cache.
    var limit: Int { get }
}

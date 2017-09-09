//
//  CacheError.swift
//  RxCache
//
//  Created by Chris Nevin on 08/07/2017.
//  Copyright © 2017 Chris Nevin. All rights reserved.
//

import Foundation

enum CacheError: Error {
    case notFound
    case notImplemented
    case expired
}

//
//  Countable.swift
//  RxCache
//
//  Created by Chris Nevin on 08/07/2017.
//  Copyright © 2017 Chris Nevin. All rights reserved.
//

import Foundation
import RxSwift

public protocol Countable {
    /// Count number of values.
    /// - returns: Number of key-value pairs.
    func count() -> Observable<Int>
}

//
//  Purgeable.swift
//  RxCache
//
//  Created by Chris Nevin on 08/07/2017.
//  Copyright © 2017 Chris Nevin. All rights reserved.
//

import Foundation
import RxSwift

public protocol Purgeable {
    /// Delete all expired values.
    /// - returns: True if anything was deleted.
    func purge() -> Observable<Bool>
}

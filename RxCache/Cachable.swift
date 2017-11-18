//
//  Cachable.swift
//  RxCache
//
//  Created by Chris Nevin on 08/07/2017.
//  Copyright © 2017 Chris Nevin. All rights reserved.
//

import Foundation
import RxSwift

public protocol Cachable {
    associatedtype Key
    associatedtype Value
    
    var cache: AnyCacheable<Key, Value> { get }
    /// Delete a single value associated with the given key.
    /// - parameter key: Key to delete.
    /// - returns: True if the key was deleted.
    func delete(key: Key) -> Observable<Bool>
    /// Check if a key exists.
    /// - parameter key: Key to find.
    /// - returns: True if the key exists.
    func has(key: Key) -> Observable<Bool>
    /// Get the value for a given key.
    /// - parameter key: Key to find.
    /// - returns: Value or CacheError.
    func get(key: Key) -> Observable<Value>
    /// Update the value for a given key.
    /// - parameter key: Key to modify/insert.
    /// - parameter value: Value to set.
    /// - returns: Echoed value parameter.
    func set(key: Key, value: Value) -> Observable<Value>
}

extension Cachable {
    public var cache: AnyCacheable<Key, Value> {
        return .init(self)
    }
    
    public func has(key: Key) -> Observable<Bool> {
        return get(key: key)
            .map({ _ in true })
            .catchErrorJustReturn(false)
    }
}

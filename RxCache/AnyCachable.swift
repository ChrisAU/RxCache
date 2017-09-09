//
//  AnyCachable.swift
//  RxCache
//
//  Created by Chris Nevin on 09/07/2017.
//  Copyright © 2017 CJNevin. All rights reserved.
//

import Foundation
import RxSwift

public class AnyCachable<K, V>: Cachable, Countable, Limitable, Purgeable {
    public typealias Key = K
    public typealias Value = V
    
    private let _count: () -> Observable<Int>
    private let _purge: () -> Observable<Bool>
    private let _get: (Key) -> Observable<Value>
    private let _set: (Key, Value) -> Observable<Value>
    private let _delete: (Key) -> Observable<Bool>
    
    public let limit: Int
    
    init<T: Cachable>(_ cachable: T) where T.Key == Key, T.Value == Value {
        _get = cachable.get
        _set = cachable.set
        _delete = cachable.delete
        _purge = (cachable as? Purgeable)?.purge ?? { _ in .error(CacheError.notImplemented) }
        _count = (cachable as? Countable)?.count ?? { _ in .error(CacheError.notImplemented) }
        limit = (cachable as? Limitable)?.limit ?? 0
    }
    
    public func count() -> Observable<Int> {
        return _count()
    }
    
    public func purge() -> Observable<Bool> {
        return _purge()
    }
    
    public func get(key: Key) -> Observable<Value> {
        return _get(key)
    }
    
    public func set(key: Key, value: Value) -> Observable<Value> {
        return _set(key, value)
    }
    
    public func delete(key: Key) -> Observable<Bool> {
        return _delete(key)
    }
}

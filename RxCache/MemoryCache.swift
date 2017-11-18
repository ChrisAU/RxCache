//
//  MemoryCache.swift
//  RxCache
//
//  Created by Chris Nevin on 08/07/2017.
//  Copyright © 2017 Chris Nevin. All rights reserved.
//

import Foundation
import RxSwift

public struct MemoryCache<K: Hashable, V>: Cacheable, Countable, Limitable, Purgeable {
    public typealias Key = K
    public typealias Value = V
    
    typealias KeyValueType = (key: Key, value: Value)
    
    private let observeOnScheduler = SerialDispatchQueueScheduler(qos: .background)
    private let keyValues = Variable<[KeyValueType]>([])
    
    public let limit: Int
    
    public init(limit: Int = 0) {
        self.limit = limit
    }
    
    private func latest() -> Observable<[KeyValueType]> {
        return keyValues.asObservable()
            .take(1)
            .observeOn(observeOnScheduler)
    }
    
    /// Keys for expired values.
    private var expiredKeys: Observable<[Key]> {
        return latest().map { $0.flatMap({ (key, value) in ((value as? Expirable)?.hasExpired ?? false) ? key : nil }) }
    }
    
    public func count() -> Observable<Int> {
        return latest().map({ $0.count })
    }
    
    public func purge() -> Observable<Bool> {
        // executes on background thread
        return expiredKeys.flatMap(delete)
    }
    
    /// Delete multiple keys.
    /// - parameter keys: Keys to attempt deletion of.
    /// - returns: True if any of the keys were able to be deleted.
    func delete(keys: [Key]) -> Observable<Bool> {
        return keys.reduce(.just(false)) { (current, key) -> Observable<Bool> in
            current.flatMap({ removed in self._delete(key: key).map({ $0 || removed }) })
        }.observeOn(observeOnScheduler)
    }
    
    /// Delete a single value associated with the given key (on current thread).
    /// - parameter key: Key to delete.
    /// - returns: True if the key was deleted.
    @discardableResult private func remove(key: Key) -> Bool {
        let newKeyValues = keyValues.value.filter({ $0.key != key })
        let changed = keyValues.value.count != newKeyValues.count
        keyValues.value = newKeyValues
        return changed
    }
    
    /// Delete a single value associated with the given key (on current thread).
    /// - parameter key: Key to delete.
    /// - returns: True if the key was deleted.
    private func _delete(key: Key) -> Observable<Bool> {
        return Observable.just(self.remove(key: key))
    }
    
    public func delete(key: Key) -> Observable<Bool> {
        return Observable.just(self.remove(key: key), scheduler: observeOnScheduler)
    }
    
    public func get(key: Key) -> Observable<Value> {
        // executes on background thread
        return latest().flatMap({ values -> Observable<Value> in
            guard let value = values.filter({ $0.key == key }).first?.value else { return .error(CacheError.notFound) }
            // Return object, if not expired
            guard (value as? Expirable)?.hasExpired == true else { return .just(value) }
            // Remove expired object and return not found error
            return self._delete(key: key).map({ _ in throw CacheError.expired })
        })
    }
    
    public func set(key: Key, value: Value) -> Observable<Value> {
        func add() {
            remove(key: key)
            keyValues.value.append((key, value))
            if limit > 0 && keyValues.value.count > limit, let keyToRemove = keyValues.value.first?.key {
                remove(key: keyToRemove)
            }
        }
        return Observable.just(add(), scheduler: observeOnScheduler).map({ value })
    }
}

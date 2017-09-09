//
//  CompositeCache.swift
//  RxCache
//
//  Created by Chris Nevin on 08/07/2017.
//  Copyright © 2017 Chris Nevin. All rights reserved.
//

import Foundation
import RxSwift

public struct CompositeCache<K, V>: Cachable, Purgeable {
    public typealias Key = K
    public typealias Value = V
    
    private let sequence: Observable<AnyCachable<Key, Value>>
    
    public init<C: Cachable>(caches: [C]) where C.Key == Key, C.Value == Value {
        let observables = caches.map({ $0.cache }).map(Observable.just)
        sequence = Observable.concat(observables)
    }
    
    public init(caches: [AnyCachable<Key, Value>]) {
        let observables = caches.map(Observable.just)
        sequence = Observable.concat(observables)
    }
    
    private func executeFirst<U>(_ block: @escaping (Observable<U>?, AnyCachable<Key, Value>) -> Observable<U>) -> Observable<U> {
        return sequence
            .reduce(nil) { (result, cache) -> Observable<U> in
                guard let latestResult = result else {
                    return block(result, cache)
                }
                return latestResult.catchError({ _ in block(latestResult, cache) })
            }
            .flatMap({ $0! })   // Force unwrap value, error would have been thrown if unsuccessful
    }
    
    private func executeAll<U>(_ block: @escaping (Observable<U>?, AnyCachable<Key, Value>) -> Observable<U>) -> Observable<U> {
        return sequence
            .reduce(nil) { (result, cache) -> Observable<U> in
                guard let latestResult = result else {
                    return block(result, cache)
                }
                return latestResult.flatMap({ _ in block(latestResult, cache) })
            }
            .flatMap({ $0! })   // Force unwrap value, error would have been thrown if unsuccessful
    }
    
    public func purge() -> Observable<Bool> {
        return executeAll { (result, cache) in
            cache.purge().catchError({ (error) -> Observable<Bool> in
                return result ?? .just(false)
            })
        }
    }
    
    public func get(key: Key) -> Observable<Value> {
        return executeFirst { (_, cache) in
            cache.get(key: key)
        }.flatMap { self.update(key: key, value: $0) }
    }
    
    func update(key: Key, value: Value) -> Observable<Value> {
        return executeAll { (_, cache) in
            cache.has(key: key).flatMap({ $0 ? .just(value) : cache.set(key: key, value: value) })
        }
    }
    
    public func set(key: Key, value: Value) -> Observable<Value> {
        return executeAll { (_, cache) in
            cache.set(key: key, value: value)
        }
    }
    
    public func delete(key: Key) -> Observable<Bool> {
        return executeAll { (_, cache) in
            cache.delete(key: key)
        }
    }
}

//
//  UserDefaultsCache.swift
//  RxCache
//
//  Created by Chris Nevin on 08/07/2017.
//  Copyright © 2017 CJNevin. All rights reserved.
//

import Foundation
import RxSwift

public struct UserDefaultsCache<V>: Cachable {
    public typealias Key = String
    public typealias Value = V
    
    private let observeOnScheduler = SerialDispatchQueueScheduler(qos: .background)
    private let userDefaults: UserDefaults
    
    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }
    
    public func get(key: Key) -> Observable<Value> {
        guard let value = userDefaults.value(forKey: key) as? Value else {
            return .error(CacheError.notFound)
        }
        return .just(value, scheduler: observeOnScheduler)
    }
    
    public func set(key: Key, value: Value) -> Observable<Value> {
        return Observable.create({ (observer) -> Disposable in
            self.userDefaults.set(value, forKey: key)
            self.userDefaults.synchronize()
            observer.onNext(value)
            observer.onCompleted()
            return Disposables.create()
        }).observeOn(observeOnScheduler)
    }
    
    public func delete(key: Key) -> Observable<Bool> {
        // executes on background thread
        return get(key: key)
            .map({ _ in self.userDefaults.removeObject(forKey: key); return true })
            .catchErrorJustReturn(false)
    }
}

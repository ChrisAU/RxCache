//
//  MemoryCacheTests.swift
//  RxCache
//
//  Created by Chris Nevin on 08/07/2017.
//  Copyright © 2017 CJNevin. All rights reserved.
//

import Foundation
import RxSwift
import XCTest
@testable import RxCache

extension Bool: Expirable {
    public var hasExpired: Bool {
        return self
    }
}

extension String: Expirable {
    public var hasExpired: Bool {
        return false
    }
}

class MemoryCacheTests: XCTestCase {
    var disposeBag: DisposeBag!
    
    override func setUp() {
        disposeBag = DisposeBag()
    }
    
    override func tearDown() {
        disposeBag = nil
    }
     
    func testDeleteSucceeds() {
        let expect = expectation(description: "delete succeeds for unknown key")
        let cache = MemoryCache<String, Bool>()
        cache.set(key: "a", value: false)
            .flatMap({ _ in cache.delete(key: "a") })
            .subscribe(onNext: { (success) in
                XCTAssertTrue(success)
                expect.fulfill()
            })
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 1, handler: { _ in })
    }
    
    func testDeleteFailsForUnknownKey() {
        let expect = expectation(description: "delete fails for unknown key")
        let cache = MemoryCache<String, Bool>()
        cache.delete(key: "a")
            .subscribe(onNext: { (success) in
                XCTAssertFalse(success)
                expect.fulfill()
            })
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 1, handler: { _ in })
    }
    
    func testGetFailsForExpired() {
        let expect = expectation(description: "get fails due to expired")
        let cache = MemoryCache<String, Bool>()
        cache.set(key: "a", value: true)
            .flatMap({ _ in cache.get(key: "a") })
            .subscribe(onError: { (error) in
                switch error {
                case CacheError.expired: expect.fulfill()
                default: XCTFail()
                }
            })
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 1, handler: { _ in })
    }
    
    func testGetSucceeds() {
        let expect = expectation(description: "get succeeds")
        let cache = MemoryCache<String, Bool>()
        cache.set(key: "a", value: false)
            .flatMap({ _ in cache.get(key: "a") })
            .subscribe(onNext: { (value) in
                XCTAssertFalse(value)
                expect.fulfill()
            })
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 1, handler: { _ in })
    }
    
    func testHasFailsForExpired() {
        let expect = expectation(description: "has fails due to expired")
        let cache = MemoryCache<String, Bool>()
        cache.set(key: "a", value: true)
            .flatMap({ _ in cache.has(key: "a") })
            .subscribe(onNext: { (hasValue) in
                XCTAssertFalse(hasValue)
                expect.fulfill()
            })
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 1, handler: { _ in })
    }
    
    func testHasSucceeds() {
        let expect = expectation(description: "has succeeds")
        let cache = MemoryCache<String, Bool>()
        cache.set(key: "a", value: false)
            .flatMap({ _ in cache.has(key: "a") })
            .subscribe(onNext: { (hasValue) in
                XCTAssertTrue(hasValue)
                expect.fulfill()
            })
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 1, handler: { _ in })
    }
    
    func testPurgeRemovesExpiredItems() {
        let expect = expectation(description: "purge")
        let cache = MemoryCache<String, Bool>()
        cache.set(key: "a", value: true)
            .flatMap({ _ in cache.set(key: "b", value: true) })
            .flatMap({ _ in cache.set(key: "c", value: false) })
            .flatMap({ _ in cache.set(key: "d", value: true) })
            .flatMap({ _ in cache.purge() })
            .flatMap({ _ in cache.count() })
            .subscribe(onNext: { count in
                XCTAssertEqual(count, 1)
                expect.fulfill()
            })
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: 1, handler: { _ in })
    }
    
    func testLimitIsRespected() {
        let expect = expectation(description: "limit is respected")
        let cache = MemoryCache<String, String>(limit: 2)
        cache.set(key: "a", value: "a")
            .flatMap({ _ in cache.set(key: "b", value: "b") })
            .flatMap({ _ in cache.set(key: "c", value: "c") })
            .flatMap({ _ in cache.count() })
            .subscribe(onNext: { count in
                XCTAssertEqual(count, cache.limit)
                expect.fulfill()
            })
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: 1, handler: { _ in })
    }
    
    func testCacheIsRotatedIfLimitIsExceeded() {
        let expect = expectation(description: "cache is rotated")
        let cache = MemoryCache<String, String>(limit: 2)
        cache.set(key: "a", value: "a")
            // a -> b
            .flatMap({ _ in cache.set(key: "b", value: "b") })
            // b -> c (drop a)
            .flatMap({ _ in cache.set(key: "c", value: "c") })
            .flatMap({ _ in cache.get(key: "a") })
            .catchError({ (error) -> Observable<String> in
                switch error {
                case CacheError.notFound:
                    // c -> d (drop b)
                    return cache.set(key: "d", value: "d")
                default:
                    return .error(error)
                }
            })
            .flatMap({ _ in cache.get(key: "b") })
            .catchError({ (error) -> Observable<String> in
                switch error {
                case CacheError.notFound:
                    // d -> e (drop c)
                    return cache.set(key: "e", value: "e")
                default:
                    return .error(error)
                }
            })
            .flatMap({ _ in cache.get(key: "c") })
            .catchError({ (error) -> Observable<String> in
                switch error {
                case CacheError.notFound:
                    return cache.get(key: "d")
                default:
                    return .error(error)
                }
            })
            .do(onNext: { _ in expect.fulfill() },
                onError: { _ in XCTFail() })
            .subscribe()
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: 1, handler: { _ in })
    }
}

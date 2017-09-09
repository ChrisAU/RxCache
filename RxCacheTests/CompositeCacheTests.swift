//
//  CompositeCacheTests.swift
//  RxCache
//
//  Created by Chris Nevin on 08/07/2017.
//  Copyright © 2017 CJNevin. All rights reserved.
//

import Foundation
import RxSwift
import XCTest
@testable import RxCache

struct TestObject: Expirable {
    let value: String
    let hasExpired: Bool
}

class CompositeCacheTests: XCTestCase {
    var disposeBag: DisposeBag!
    
    override func setUp() {
        disposeBag = DisposeBag()
    }
    
    override func tearDown() {
        disposeBag = nil
    }
	
	/*
    func testPurgeSkipsUnpurgableCache() {
        let expect = expectation(description: "purge falls through")
        let userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        let a = MemoryCache<String, Bool>()
        let b = UserDefaultsCache<Bool>(userDefaults: userDefaults)
        let composite = CompositeCache(caches: [a.cache, b.cache])
        
        composite.set(key: "test", value: true)
            .flatMap({ _ in composite.purge() })
            .do(onNext: { success in
                XCTAssertTrue(success)
            })
            .withLatestFrom(a.has(key: "test"))
            .do(onNext: { success in
                XCTAssertFalse(success)
            })
            .withLatestFrom(b.has(key: "test"))
            .subscribe(onNext: { success in
                XCTAssertTrue(success)
                expect.fulfill()
            })
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 1, handler: { _ in })
    }
	*/
    
    func testPurgeFallsThrough() {
        let expect = expectation(description: "purge falls through")
        let a = MemoryCache<String, TestObject>()
        let b = MemoryCache<String, TestObject>()
        let c = MemoryCache<String, TestObject>()
        let composite = CompositeCache(caches: [a, b, c])
        
        composite.set(key: "test", value: .init(value: "test", hasExpired: true))
            .flatMap({ _ in composite.purge() })
            .do(onNext: { success in
                XCTAssertTrue(success)
            })
            .withLatestFrom(a.has(key: "test"))
            .do(onNext: { success in
                XCTAssertFalse(success)
            })
            .withLatestFrom(b.has(key: "test"))
            .do(onNext: { success in
                XCTAssertFalse(success)
            })
            .withLatestFrom(c.has(key: "test"))
            .subscribe(onNext: { success in
                XCTAssertFalse(success)
                expect.fulfill()
            })
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 1, handler: { _ in })
    }
    
    func testDeleteFallsThroughOnError() {
        let expect = expectation(description: "get falls through")
        
        let a = MemoryCache<String, String>()
        let b = MemoryCache<String, String>()
        let c = MemoryCache<String, String>()
        let composite = CompositeCache(caches: [a, b, c])
        
        c.set(key: "test", value: "test")
            .flatMap({ _ in composite.delete(key: "test") })
            .subscribe(onNext: { success in
                XCTAssertTrue(success)
                expect.fulfill()
            })
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: 1, handler: { _ in })
    }
    
    func testDeleteFallsThroughAndClearsAll() {
        let expect = expectation(description: "get falls through")
        
        let a = MemoryCache<String, String>()
        let b = MemoryCache<String, String>()
        let c = MemoryCache<String, String>()
        let composite = CompositeCache(caches: [a, b, c])
        
        composite.set(key: "test", value: "test")
            .flatMap({ _ in composite.delete(key: "test") })
            .do(onNext: { success in
                XCTAssertTrue(success)
            })
            .withLatestFrom(a.has(key: "test"))
            .do(onNext: { success in
                XCTAssertFalse(success)
            })
            .withLatestFrom(b.has(key: "test"))
            .do(onNext: { success in
                XCTAssertFalse(success)
            })
            .withLatestFrom(c.has(key: "test"))
            .subscribe(onNext: { success in
                XCTAssertFalse(success)
                expect.fulfill()
            })
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: 1, handler: { _ in })
    }
    
    func testGetFallsThrough() {
        let expect = expectation(description: "get falls through")
        
        let a = MemoryCache<String, String>()
        let b = MemoryCache<String, String>()
        let c = MemoryCache<String, String>()
        let composite = CompositeCache(caches: [a, b, c])
        
        c.set(key: "test", value: "test")
            .flatMap({ _ in composite.get(key: "test") })
            .subscribe(onNext: { _ in
                expect.fulfill()
            })
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: 1, handler: { _ in })
    }
    
    func testGetSkipsExpiredValues() {
        let expect = expectation(description: "get skips expired")
        
        let a = MemoryCache<String, TestObject>()
        let b = MemoryCache<String, TestObject>()
        let c = MemoryCache<String, TestObject>()
        let composite = CompositeCache(caches: [a, b, c])
        
        a.set(key: "test", value: .init(value: "a", hasExpired: true))
            .flatMap({ _ in b.set(key: "test", value: .init(value: "b", hasExpired: true)) })
            .flatMap({ _ in c.set(key: "test", value: .init(value: "c", hasExpired: false)) })
            .flatMap({ _ in composite.get(key: "test") })
            .debug()
            .subscribe(onNext: { value in
                XCTAssertEqual(value.value, "c")
                expect.fulfill()
            })
            
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: 1, handler: { _ in })
    }
    
    func testGetDoesNotFallThrough() {
        let expect = expectation(description: "get does not fall through")
        
        let a = MemoryCache<String, String>()
        let b = MemoryCache<String, String>()
        let c = MemoryCache<String, String>()
        let composite = CompositeCache(caches: [a, b, c])
        
        a.set(key: "test", value: "a")
            .flatMap({ _ in b.set(key: "test", value: "b") })
            .flatMap({ _ in c.set(key: "test", value: "c") })
            .flatMap({ _ in composite.get(key: "test") })
            .subscribe(onNext: { value in
                XCTAssertEqual(value, "a")
                expect.fulfill()
            })
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: 1, handler: { _ in })
    }
}

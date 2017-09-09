//
//  UserDefaultsCacheTests.swift
//  RxCache
//
//  Created by Chris Nevin on 08/07/2017.
//  Copyright © 2017 CJNevin. All rights reserved.
//

import Foundation
import RxSwift
import XCTest
@testable import RxCache

class UserDefaultsCacheTests: XCTestCase {
    var disposeBag: DisposeBag!
    var userDefaults: UserDefaults!
    
    override func setUp() {
        disposeBag = DisposeBag()
        userDefaults = UserDefaults(suiteName: UUID().uuidString)
    }
    
    override func tearDown() {
        disposeBag = nil
        userDefaults = nil
    }

    func testDeleteSucceeds() {
        let expect = expectation(description: "delete succeeds for unknown key")
        let cache = UserDefaultsCache<Bool>(userDefaults: userDefaults)
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
        let cache = UserDefaultsCache<Bool>(userDefaults: userDefaults)
        cache.delete(key: "a")
            .subscribe(onNext: { (success) in
                XCTAssertFalse(success)
                expect.fulfill()
            })
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 1, handler: { _ in })
    }
    
    func testGetFailsForUnknownKey() {
        let expect = expectation(description: "get fails due to not found")
        let cache = UserDefaultsCache<Bool>(userDefaults: userDefaults)
        cache.get(key: "a")
            .subscribe(onError: { (error) in
                switch error {
                case CacheError.notFound: expect.fulfill()
                default: XCTFail()
                }
            })
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 1, handler: { _ in })
    }
    
    func testGetSucceeds() {
        let expect = expectation(description: "get succeeds")
        let cache = UserDefaultsCache<Bool>(userDefaults: userDefaults)
        cache.set(key: "a", value: false)
            .flatMap({ _ in cache.get(key: "a") })
            .subscribe(onNext: { (value) in
                XCTAssertFalse(value)
                expect.fulfill()
            })
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 1, handler: { _ in })
    }
    
    func testHasFailsForUnknownKey() {
        let expect = expectation(description: "has fails due to expired")
        let cache = UserDefaultsCache<Bool>(userDefaults: userDefaults)
        cache.has(key: "a")
            .subscribe(onNext: { (hasValue) in
                XCTAssertFalse(hasValue)
                expect.fulfill()
            })
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 1, handler: { _ in })
    }
    
    func testHasSucceeds() {
        let expect = expectation(description: "has succeeds")
        let cache = UserDefaultsCache<Bool>(userDefaults: userDefaults)
        cache.set(key: "a", value: false)
            .flatMap({ _ in cache.has(key: "a") })
            .subscribe(onNext: { (hasValue) in
                XCTAssertTrue(hasValue)
                expect.fulfill()
            })
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 1, handler: { _ in })
    }
}

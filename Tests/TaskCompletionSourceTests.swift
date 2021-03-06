/*
 *  Copyright (c) 2016, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 */

import XCTest
import BoltsSwift

class TaskCompletionSourceTests: XCTestCase {

    func testInit() {
        let sut = TaskCompletionSource<String>()
        let task = sut.task

        XCTAssertFalse(task.completed)
        XCTAssertFalse(task.faulted)
        XCTAssertFalse(task.cancelled)
        XCTAssertNil(task.result)
        XCTAssertNil(task.error)
    }

    func testSetResult() {
        let sut = TaskCompletionSource<String>()
        let task = sut.task

        sut.setResult(currentTestName)

        XCTAssertTrue(task.completed)
        XCTAssertNotNil(task.result)
        XCTAssertEqual(task.result, name)
    }

    func testSetError() {
        let error = NSError(domain: "com.bolts", code: 1, userInfo: nil)
        let sut = TaskCompletionSource<String>()
        let task = sut.task

        sut.setError(error)

        XCTAssertTrue(task.completed)
        XCTAssertTrue(task.faulted)
        XCTAssertNotNil(task.error)
        XCTAssertEqual(task.error as? NSError, error)
    }

    func testCancel() {
        let sut = TaskCompletionSource<String>()
        let task = sut.task

        sut.cancel()

        XCTAssertTrue(task.completed)
        XCTAssertTrue(task.cancelled)
    }

    func testTrySetResultReturningTrue() {
        let sut = TaskCompletionSource<String>()
        let task = sut.task

        let success = sut.trySetResult(currentTestName)

        XCTAssertTrue(success)
        XCTAssertTrue(task.completed)
        XCTAssertNotNil(task.result)
        XCTAssertEqual(task.result, name)
    }

    func testTrySetErrorReturningTrue() {
        let error = NSError(domain: "com.bolts", code: 1, userInfo: nil)
        let sut = TaskCompletionSource<String>()
        let task = sut.task

        let success = sut.trySetError(error)

        XCTAssertTrue(success)
        XCTAssertTrue(task.completed)
        XCTAssertTrue(task.faulted)
        XCTAssertNotNil(task.error)
        XCTAssertEqual(task.error as? NSError, error)
    }

    func testTryCancelReturningTrue() {
        let sut = TaskCompletionSource<String>()
        let task = sut.task

        let success = sut.tryCancel()

        XCTAssertTrue(success)
        XCTAssertTrue(task.completed)
        XCTAssertTrue(task.cancelled)
    }

    func testTrySetResultReturningFalse() {
        let sut = TaskCompletionSource<String>()
        sut.setResult(currentTestName)

        let success = sut.trySetResult(currentTestName)

        XCTAssertFalse(success)
    }

    func testTrySetErrorReturningFalse() {
        let error = NSError(domain: "com.bolts", code: 1, userInfo: nil)
        let sut = TaskCompletionSource<String>()
        sut.setResult(currentTestName)

        let success = sut.trySetError(error)

        XCTAssertFalse(success)
    }

    func testTryCancelReturningFalse() {
        let sut = TaskCompletionSource<String>()
        sut.setResult(currentTestName)
        let success = sut.tryCancel()
        XCTAssertFalse(success)
    }
}

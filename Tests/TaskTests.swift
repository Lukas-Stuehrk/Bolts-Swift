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

class TaskTests: XCTestCase {

    // MARK: Initializers

    func testWithResult() {
        let task = Task(currentTestName)

        XCTAssertNotNil(task.result)
        XCTAssertEqual(task.result, currentTestName)
        XCTAssertTrue(task.completed)
        XCTAssertFalse(task.faulted)
        XCTAssertFalse(task.cancelled)
        XCTAssertNil(task.error)
    }

    func testWithError() {
        let error = NSError(domain: "com.bolts", code: 1, userInfo: nil)
        let task = Task<String>(error: error)

        XCTAssertNil(task.result)
        XCTAssertTrue(task.completed)
        XCTAssertTrue(task.faulted)
        XCTAssertFalse(task.cancelled)
        XCTAssertNotNil(task.error)
        XCTAssertEqual(task.error as? NSError, error)
    }

    func testCancelledTask() {
        let task = Task<String>.cancelledTask()

        XCTAssertNil(task.result)
        XCTAssertTrue(task.completed)
        XCTAssertFalse(task.faulted)
        XCTAssertTrue(task.cancelled)
        XCTAssertNil(task.error)
    }

    // MARK: Task with Delay

    func testWithDelay() {
        let expectation = expectationWithDescription(currentTestName)
        let task = Task<String>.withDelay(0.01)
        task.continueWith { task in
            expectation.fulfill()
        }

        XCTAssertFalse(task.completed)
        waitForExpectationsWithTimeout(0.5, handler: nil)
    }

    // MARK: Execute

    func testExecuteWithClosureReturningNil() {
        let expectation = expectationWithDescription(currentTestName)
        let task = Task<String> {
            expectation.fulfill()
            return "Hello, World!"
        }
        waitForExpectationsWithTimeout(0.5, handler: nil)
        XCTAssertEqual(task.result, "Hello, World!")
    }

    func testExecuteWithClosureReturningValue() {
        let expectation = expectationWithDescription(currentTestName)
        let task = Task<String> {
            expectation.fulfill()
            return self.currentTestName
        }
        waitForExpectationsWithTimeout(0.5, handler: nil)
        XCTAssertNotNil(task.result)
        XCTAssertEqual(task.result, name)
    }

    func testExecuteWithClosureReturningTaskWithResult() {
        let expectation = expectationWithDescription(currentTestName)
        let task = Task.executeWithTask { () -> Task<Int> in
            expectation.fulfill()
            return Task(10)
        }
        waitForExpectationsWithTimeout(0.5, handler: nil)
        XCTAssertNotNil(task.result)
        XCTAssertEqual(task.result, 10)
    }

    func testExecuteWithClosureReturningCancelledTask() {
        let expectation = expectationWithDescription(currentTestName)
        let task = Task<Void>.executeWithTask { () -> Task<Void> in
            expectation.fulfill()
            return Task<Void>.cancelledTask()
        }
        waitForExpectationsWithTimeout(0.5, handler: nil)
        XCTAssertTrue(task.cancelled)
    }

    // MARK: Continuations

    func testContinueWithOnSucessfulTaskByReturningResult() {
        let expectation = expectationWithDescription("continuationTaskSucceeds")
        let initialTask = Task(1)

        let continuationTask = initialTask.continueWith { task -> String? in
            XCTAssertTrue(task === initialTask)
            return self.name
        }

        continuationTask.continueOnSuccessWith {
            XCTAssertEqual($0, self.name)
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(0.5, handler: nil)
    }

    func testContinueWithOnErroredTaskByReturningResult() {
        let error = NSError(domain: "com.bolts", code: 1, userInfo: nil)
        let expectation = expectationWithDescription("continuationTaskSucceeds")
        let initialTask = Task<Int>(error: error)

        let continuationTask = initialTask.continueWith { task -> String? in
            XCTAssertTrue(task === initialTask)
            return self.name
        }

        continuationTask.continueOnSuccessWith {
            XCTAssertEqual($0, self.name)
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(0.5, handler: nil)
    }

    func testContinueWithOnCancelledTaskByReturningResult() {
        let expectation = expectationWithDescription("continuationTaskSucceeds")
        let initialTask = Task<Int>.cancelledTask()

        let continuationTask = initialTask.continueWith { task -> String? in
            XCTAssertTrue(task === initialTask)
            return self.name
        }

        continuationTask.continueOnSuccessWith {
            XCTAssertEqual($0, self.name)
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(0.5, handler: nil)
    }

    func testContinueWithWithExecutor() {
        let expectation = expectationWithDescription("continuationTaskSucceeds")
        let initialTask = Task<Int>.cancelledTask()
        let executorExpectation = expectationWithDescription("executor")

        let executor = Executor.Closure {
            $0()
            executorExpectation.fulfill()
        }

        let continuationTask = initialTask.continueWith(executor) { task -> String? in
            XCTAssertTrue(task === initialTask)
            return self.name
        }

        continuationTask.continueOnSuccessWith {
            XCTAssertEqual($0, self.name)
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(0.5, handler: nil)
    }

    func testContinueWithByReturningNilResult() {
        let expectation = expectationWithDescription("continuationTaskSucceeds")
        let initialTask = Task(1)

        let continuationTask = initialTask.continueWith { task -> String? in
            XCTAssertTrue(task === initialTask)
            return nil
        }

        continuationTask.continueOnSuccessWith {
            XCTAssertNil($0)
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(0.5, handler: nil)
    }

    func testContinueWithByReturningTask() {
        let expectation = expectationWithDescription("continuationTaskSucceeds")
        let firstTask = Task(1)
        let secondTask = Task(currentTestName)

        let continuationTask = firstTask.continueWithTask { task -> Task<String> in
            XCTAssertTrue(task === firstTask)
            return secondTask
        }

        XCTAssertTrue(continuationTask !== secondTask)
        continuationTask.continueOnSuccessWith {
            XCTAssertEqual($0, self.name)
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(0.5, handler: nil)
    }

    func testContinueWithByReturningNilTask() {
        let expectation = expectationWithDescription("continuationTaskCompletes")
        let initialTask = Task(1)

        let continuationTask = initialTask.continueWith { task in
            XCTAssertTrue(task === initialTask)
        }

        continuationTask.continueWith { task in
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(0.5, handler: nil)
    }

    func testChainedContinueWithFunctions() {
        let expectation = expectationWithDescription(currentTestName)
        var count = 0

        Task<Void>.cancelledTask().continueWith { _ -> String? in
            count += 1
            XCTAssertEqual(count, 1)
            return nil
            }.continueWith { _ -> String? in
                count += 1
                XCTAssertEqual(count, 2)
                return nil
            }.continueWith { _ -> String? in
                count += 1
                XCTAssertEqual(count, 3)
                return nil
            }.continueWith { _ -> String? in
                count += 1
                XCTAssertEqual(count, 4)
                return nil
            }.continueWith { _ -> String? in
                count += 1
                XCTAssertEqual(count, 5)
                expectation.fulfill()
                return nil
        }

        waitForExpectationsWithTimeout(0.5, handler: nil)
    }

    func testChainedContinueWithWithAsyncExecutor() {
        let expectation = expectationWithDescription(currentTestName)
        let executor = Executor.Queue(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0))
        var count = 0

        Task<Void>.cancelledTask().continueWith(executor) { _ in
            count += 1
            XCTAssertEqual(count, 1)
            }.continueWith(executor) { _ in
                count += 1
                XCTAssertEqual(count, 2)
            }.continueWith(executor) { _ in
                count += 1
                XCTAssertEqual(count, 3)
            }.continueWith(executor) { _ in
                count += 1
                XCTAssertEqual(count, 4)
            }.continueWith(executor) { _ in
                count += 1
                XCTAssertEqual(count, 5)
                expectation.fulfill()
        }

        waitForExpectationsWithTimeout(0.5, handler: nil)
    }

    // MARK: WhenAll

    func testWhenAllTasksSuccess() {
        var tasks = Array<Task<Int>>()
        var count: Int32 = 0

        for i in 1...20 {
            let task = Task<Void>.withDelay(NSTimeInterval(rand() % 10) / 100)
                .continueWith(continuation: { task -> Int in
                    OSAtomicIncrement32(&count)
                    return i
                })
            tasks.append(task)
        }

        let expectation = expectationWithDescription(currentTestName)
        let task = Task.whenAll(tasks).continueWith { task in
            XCTAssertEqual(count, Int32(tasks.count))
            XCTAssertTrue(task.completed)
            XCTAssertFalse(task.faulted)
            XCTAssertFalse(task.cancelled)
            expectation.fulfill()
        }

        XCTAssertFalse(task.completed)
        XCTAssertFalse(task.faulted)
        XCTAssertFalse(task.cancelled)

        waitForExpectationsWithTimeout(5.0, handler: nil)
    }

    func testWhenAllTasksWithResultSuccess() {
        var tasks = Array<Task<Int>>()
        var count: Int32 = 0
        let executor = Executor.Queue(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0))

        for i in 1...20 {
            let task = Task<Void>.withDelay(NSTimeInterval(rand() % 10) / 100)
                .continueWith(executor, continuation: { task -> Int in
                    OSAtomicIncrement32(&count)
                    return i
                })
            tasks.append(task)
        }

        let expectation = expectationWithDescription(currentTestName)
        let task = Task.whenAllResult(tasks).continueWith { task in
            XCTAssertEqual(count, Int32(tasks.count))
            XCTAssertTrue(task.completed)
            XCTAssertFalse(task.faulted)
            XCTAssertFalse(task.cancelled)
            XCTAssertEqual(Int32(task.result!.count), count)
            expectation.fulfill()
        }

        XCTAssertFalse(task.completed)
        XCTAssertFalse(task.faulted)
        XCTAssertFalse(task.cancelled)

        waitForExpectationsWithTimeout(5.0, handler: nil)
    }

    func testWhenAllTasksWithCancel() {
        var tasks = Array<Task<Int>>()
        var count: Int32 = 0
        let executor = Executor.Queue(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0))

        for i in 1...20 {
            let task = Task<Void>.withDelay(NSTimeInterval(rand() % 10) / 100)
                .continueWithTask(executor, continuation: { task -> Task<Int> in
                    OSAtomicIncrement32(&count)
                    if i == 20 {
                        return Task.cancelledTask()
                    }
                    return Task(i)
                })
            tasks.append(task)
        }

        let expectation = expectationWithDescription(currentTestName)
        let task = Task.whenAllResult(tasks).continueWith { task in
            XCTAssertEqual(count, Int32(tasks.count))
            XCTAssertTrue(task.completed)
            XCTAssertFalse(task.faulted)
            XCTAssertTrue(task.cancelled)
            expectation.fulfill()
        }

        XCTAssertFalse(task.completed)
        XCTAssertFalse(task.faulted)
        XCTAssertFalse(task.cancelled)

        waitForExpectationsWithTimeout(5.0, handler: nil)

    }

    // MARK: When Any

    func testWhenAnyTasksSuccess() {
        var tasks = Array<Task<Int>>()
        var count: Int32 = 0
        let executor = Executor.Queue(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0))

        for i in 1...20 {
            let task = Task<Void>.withDelay(NSTimeInterval(rand() % 100) / 100)
                .continueWith(executor, continuation: { task -> Int in
                    OSAtomicIncrement32(&count)
                    return i
                })
            tasks.append(task)
        }

        let expectation = expectationWithDescription(currentTestName)
        let task = Task.whenAny(tasks).continueWith { task in
            XCTAssertNotEqual(count, Int32(tasks.count))
            XCTAssertTrue(task.completed)
            XCTAssertFalse(task.faulted)
            XCTAssertFalse(task.cancelled)
            expectation.fulfill()
        }

        XCTAssertFalse(task.completed)
        XCTAssertFalse(task.faulted)
        XCTAssertFalse(task.cancelled)

        waitForExpectationsWithTimeout(0.5, handler: nil)
    }

    func testWhenAnyTasksWithErrors() {
        var tasks = Array<Task<Void>>()
        var count: Int32 = 0

        let executor = Executor.Queue(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0))
        let error = NSError(domain: "com.bolts", code: 1, userInfo: nil)

        for _ in 1...20 {
            let task = Task<Void>.withDelay(NSTimeInterval(rand() % 100) / 100)
                .continueWithTask(executor, continuation: { task -> Task<Void> in
                    OSAtomicIncrement32(&count)
                    return Task(error: error)
                })
            tasks.append(task)
        }

        let expectation = expectationWithDescription(currentTestName)
        let task = Task.whenAny(tasks).continueWith { task in
            XCTAssertNotEqual(count, Int32(tasks.count))
            XCTAssertTrue(task.completed)
            XCTAssertFalse(task.faulted)
            XCTAssertFalse(task.cancelled)
            expectation.fulfill()
        }

        XCTAssertFalse(task.completed)
        XCTAssertFalse(task.faulted)
        XCTAssertFalse(task.cancelled)

        waitForExpectationsWithTimeout(0.5, handler: nil)
    }

    func testWhenAnyTasksWithCancel() {
        var tasks = Array<Task<Int>>()
        var count: Int32 = 0

        let executor = Executor.Queue(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0))

        for _ in 1...20 {
            let task = Task<Void>.withDelay(NSTimeInterval(rand() % 100) / 100)
                .continueWithTask(executor, continuation: { task -> Task<Int> in
                    OSAtomicIncrement32(&count)
                    return Task.cancelledTask()
                })
            tasks.append(task)
        }

        let expectation = expectationWithDescription(currentTestName)
        let task = Task.whenAny(tasks).continueWith { task in
            XCTAssertNotEqual(count, Int32(tasks.count))
            XCTAssertTrue(task.completed)
            XCTAssertFalse(task.faulted)
            XCTAssertFalse(task.cancelled)
            expectation.fulfill()
        }

        XCTAssertFalse(task.completed)
        XCTAssertFalse(task.faulted)
        XCTAssertFalse(task.cancelled)

        waitForExpectationsWithTimeout(0.5, handler: nil)
    }

    // MARK: Wait

    func testTaskWait() {
        Task<Void>.withDelay(0.5).waitUntilCompleted()
    }

    func testCompletedTaskWait() {
        Task(self.name).waitUntilCompleted()
    }

    func testTaskChainWait() {
        var count = 0

        Task<Void>.cancelledTask().continueWith { _ in
            count += 1
            XCTAssertEqual(count, 1)
            }.continueWith { _ in
                count += 1
                XCTAssertEqual(count, 2)
            }.continueWith { _ in
                count += 1
                XCTAssertEqual(count, 3)
            }.continueWith { _ in
                count += 1
                XCTAssertEqual(count, 4)
            }.continueWith { _ in
                count += 1
                XCTAssertEqual(count, 5)
            }.waitUntilCompleted()
        XCTAssertEqual(count, 5)
    }
}

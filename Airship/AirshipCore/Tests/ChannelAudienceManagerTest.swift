/* Copyright Airship and Contributors */

import XCTest

@testable
import AirshipCore

class ChannelAudienceManagerTest: XCTestCase {
    
    var taskManager: TestTaskManager!
    var notificationCenter: NotificationCenter!
    var date: UATestDate!
    var privacyManager: UAPrivacyManager!
    var dataStore: UAPreferenceDataStore!
    var subscriptionListClient: TestSubscriptionListAPIClient!
    var audienceManager: ChannelAudienceManager!

    override func setUpWithError() throws {
        self.notificationCenter = NotificationCenter()
        self.taskManager = TestTaskManager()
        self.subscriptionListClient = TestSubscriptionListAPIClient()
        self.subscriptionListClient.defaultCallback = { method in
            XCTFail("Method \(method) called unexpectedly")
        }
    
        self.date = UATestDate()
        self.dataStore = UAPreferenceDataStore(keyPrefix: UUID().uuidString)
        self.privacyManager = UAPrivacyManager(dataStore: self.dataStore, defaultEnabledFeatures: .all, notificationCenter: self.notificationCenter)
        
        self.audienceManager = ChannelAudienceManager(dataStore: self.dataStore, taskManager: self.taskManager, subscriptionListClient: self.subscriptionListClient, privacyManager: self.privacyManager, notificationCenter: self.notificationCenter, date: self.date);
        
        self.audienceManager.enabled = true
        self.audienceManager.channelID = "some-channel"
        
        self.taskManager.enqueuedRequests.removeAll()
    }

    func testUpdates() throws {
        let editor = self.audienceManager.editSubscriptionLists()
        editor.subscribe("pizza")
        editor.unsubscribe("coffee")
        editor.apply()
        
        editor.subscribe("hotdogs")
        editor.apply()
        
        XCTAssertEqual(2, self.taskManager.enqueuedRequests.count)

        let expectation = XCTestExpectation(description: "callback called")

        self.subscriptionListClient.updateCallback = { identifier, updates, callback in
            expectation.fulfill()

            XCTAssertEqual("some-channel", identifier)
            XCTAssertEqual(3, updates.count)
            callback(UAHTTPResponse(status: 200), nil)
        }
        
        XCTAssertTrue(self.taskManager.launchSync(taskID: ChannelAudienceManager.updateTaskID).completed)

        wait(for: [expectation], timeout: 10.0)
        
        XCTAssertTrue(self.taskManager.launchSync(taskID: ChannelAudienceManager.updateTaskID).completed)
    }
    
    func testGet() throws {
        let expectedLists = ["cool", "story"]
        self.subscriptionListClient.getCallback = { identifier, callback in
            XCTAssertEqual("some-channel", identifier)
            callback(SubscriptionListFetchResponse(status: 200, listIDs: expectedLists), nil)
        }
        
        let expectation = XCTestExpectation(description: "callback called")
        self.audienceManager.fetchSubscriptionLists() { lists, error in
            XCTAssertEqual(expectedLists, lists)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testGetCache() throws {
        self.date.dateOverride = Date()
        
        var apiResult = ["cool", "story"]
        
        self.subscriptionListClient.getCallback = { identifier, callback in
            XCTAssertEqual("some-channel", identifier)
            callback(SubscriptionListFetchResponse(status: 200, listIDs: apiResult), nil)
        }
    
        // Populate cache
        var expectation = XCTestExpectation(description: "callback called")
        self.audienceManager.fetchSubscriptionLists() { lists, error in
            XCTAssertEqual(["cool", "story"], lists)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
        
        apiResult = ["some-other-result"]
        
        // From cache
        expectation = XCTestExpectation(description: "callback called")
        self.audienceManager.fetchSubscriptionLists() { lists, error in
            XCTAssertEqual(["cool", "story"], lists)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
        
        self.date.offset += 599 // 1 second before cache should invalidate
        
        // From cache
        expectation = XCTestExpectation(description: "callback called")
        self.audienceManager.fetchSubscriptionLists() { lists, error in
            XCTAssertEqual(["cool", "story"], lists)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
        
        self.date.offset += 1
        
        // From api
        expectation = XCTestExpectation(description: "callback called")
        self.audienceManager.fetchSubscriptionLists() { lists, error in
            XCTAssertEqual(["some-other-result"], lists)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testGetCacheInvalidatesOnUpate() throws {
        self.date.dateOverride = Date()
        
        var apiResult = ["cool", "story"]
        
        self.subscriptionListClient.getCallback = { identifier, callback in
            XCTAssertEqual("some-channel", identifier)
            callback(SubscriptionListFetchResponse(status: 200, listIDs: apiResult), nil)
        }
    
        // Populate cache
        var expectation = XCTestExpectation(description: "callback called")
        self.audienceManager.fetchSubscriptionLists() { lists, error in
            XCTAssertEqual(["cool", "story"], lists)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
        
        // Update
        let editor = self.audienceManager.editSubscriptionLists()
        editor.subscribe("pizza")
        editor.apply()

        expectation = XCTestExpectation(description: "callback called")
        self.subscriptionListClient.updateCallback = { identifier, updates, callback in
            expectation.fulfill()
            callback(UAHTTPResponse(status: 200), nil)
        }
        
        XCTAssertTrue(self.taskManager.launchSync(taskID: ChannelAudienceManager.updateTaskID).completed)
        wait(for: [expectation], timeout: 10.0)
        
        apiResult = ["some-other-result"]
        
        // From api
        expectation = XCTestExpectation(description: "callback called")
        self.audienceManager.fetchSubscriptionLists() { lists, error in
            XCTAssertEqual(["some-other-result"], lists)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testNoPendingOperations() throws {
        let task = self.taskManager.launchSync(taskID: ChannelAudienceManager.updateTaskID)
        XCTAssertTrue(task.completed)
        XCTAssertEqual(0, self.taskManager.enqueuedRequests.count)
    }
    
    func testEnableEnqueuesTask() throws {
        self.audienceManager.enabled = false
        XCTAssertEqual(0, self.taskManager.enqueuedRequests.count)

        self.audienceManager.enabled = true
        XCTAssertEqual(1, self.taskManager.enqueuedRequests.count)
    }
    
    func testSetChannelIDEnqueuesTask() throws {
        self.audienceManager.channelID = nil
        XCTAssertEqual(0, self.taskManager.enqueuedRequests.count)

        self.audienceManager.channelID = "sweet"
        XCTAssertEqual(1, self.taskManager.enqueuedRequests.count)
    }

    func testPrivacyManagerDisabledIgnoresUpdates() throws {
        self.privacyManager.disableFeatures(.tagsAndAttributes)
        
        let editor = self.audienceManager.editSubscriptionLists()
        editor.subscribe("pizza")
        editor.unsubscribe("coffee")
        editor.apply()
        
        self.privacyManager.enableFeatures(.tagsAndAttributes)
        let task = self.taskManager.launchSync(taskID: ChannelAudienceManager.updateTaskID)
        XCTAssertTrue(task.completed)
    }
    
}

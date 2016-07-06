//
//  MessagingUiTests.swift
//  Signal
//
//  Created by Michael Kirk on 3/31/16.
//  Copyright © 2016 Open Whisper Systems. All rights reserved.
//

import XCTest

class MessagingUITests: UITestCase {

    override func setUp() {
        super.setUp()
        app.launchArguments = [TSRunTestSetup, TSStartingStateForTestRegistered]
        app.launch()
    }

    override func tearDown() {    
        super.tearDown()
    }

    func testComposeNewMessageNavigation() {
        app.navigationBars["Conversations"].buttons["Compose"].tap()

        XCTAssert(app.navigationBars["New Message"].exists)
    }

    // requires verified app AND valid contact with name "Test"
    func testComposeMessageSelectNavigation() {
        app.navigationBars["Conversations"].buttons["Compose"].tap()
        app.tables.staticTexts["Test"].tap()

        XCTAssert(app.navigationBars["Test"].exists)
    }

    // requires verified app AND valid contact with name "Test"
    func testComposeMessageSend() {
        app.navigationBars["Conversations"].buttons["Compose"].tap()
        app.tables.staticTexts["Test"].tap()

        app.textViews.element(boundBy: app.textViews.count - 1).tap()
        app.textViews.element(boundBy: app.textViews.count - 1).typeText("1")
        app.toolbars.buttons["Send"].tap()

        XCTAssert(app.textViews["1"].exists)
    }

    // requires verified app AND valid contact with name "Test"
    func testComposeMessageSendImage() {
        app.navigationBars["Conversations"].buttons["Compose"].tap()
        app.tables.staticTexts["Test"].tap()
        let oldImagesCount = app.images.count
        app.toolbars.buttons["btnAttachments  blue"].tap()
        app.buttons["Choose from Library..."].tap()
        app.buttons["Camera Roll"].tap()
        app.cells.element(boundBy: 0).tap()

        XCTAssert(app.images.count > oldImagesCount)
    }

    // requires verified app AND valid contact with name "Test"
    func testComposeMessageSendImageOptions() {
        app.navigationBars["Conversations"].buttons["Compose"].tap()
        app.tables.staticTexts["Test"].tap()
        app.toolbars.buttons["btnAttachments  blue"].tap()
        app.buttons["Choose from Library..."].tap()
        app.buttons["Camera Roll"].tap()
        app.cells.element(boundBy: 0).tap()
        app.collectionViews.cells.otherElements.children(matching: .other).element(boundBy: 0).children(matching: .image).element.tap()
        app.buttons["savephoto"].tap()
        sleep(1)

        XCTAssert(app.buttons["Save to Camera Roll"].exists)
    }

    // requires verified app AND valid contact with name "Test"
    func testComposeMessageSendVideo() {
        app.navigationBars["Conversations"].buttons["Compose"].tap()
        app.tables.staticTexts["Test"].tap()
        let oldImagesCount = app.images.count
        app.toolbars.buttons["btnAttachments  blue"].tap()
        app.buttons["Choose from Library..."].tap()
        app.buttons["Videos"].tap()
        app.cells.element(boundBy: 0).tap()
        app.buttons["Choose"].tap()
        sleep(2)

        XCTAssert(app.images.count > oldImagesCount)
    }

    // requires verified app AND valid contact with name "Test"
    func testComposeMessageSelectSendConversationsTimestamp() {
        app.navigationBars["Conversations"].buttons["Compose"].tap()
        app.tables.staticTexts["Test"].tap()

        app.textViews.element(boundBy: app.textViews.count - 1).tap()
        app.textViews.element(boundBy: app.textViews.count - 1).typeText("1")
        app.toolbars.buttons["Send"].tap()

        let dateFormatter = DateFormatter.init()
        dateFormatter.dateStyle = .noStyle
        dateFormatter.timeStyle = .shortStyle
        let timestamp = dateFormatter.string(from: Date())

        app.buttons.element(boundBy: 0).tap()

        XCTAssert(app.tables.staticTexts[timestamp].exists)
    }

    // requires verified app AND valid contact with name "Test"
    func testComposeMessageSelectDisplayContactPhoneNumber() {
        app.navigationBars["Conversations"].buttons["Compose"].tap()
        app.tables.staticTexts["Test"].tap()

        app.navigationBars.staticTexts["Test"].tap()

        XCTAssert(app.navigationBars.staticTexts["+x xxx-xxx-xxxx"].exists)
    }

    // requires verified app AND valid contact with name "Test"
    func testComposeMessageAttachmentAlert() {
        app.navigationBars["Conversations"].buttons["Compose"].tap()
        app.tables.staticTexts["Test"].tap()
        sleep(2)
        app.toolbars.buttons["btnAttachments  blue"].tap()

        print(XCUIApplication().debugDescription)

        XCTAssert(app.buttons["Take Photo or Video"].exists)
    }

    // requires verified app AND valid contact with name "Test"
    func testComposeMessageFingerprintNavigation() {
        app.navigationBars["Conversations"].buttons["Compose"].tap()
        app.tables.staticTexts["Test"].tap()
        app.navigationBars["Test"].staticTexts["Test"].press(forDuration: 1.0)

        XCTAssert(app.staticTexts["Your Fingerprint"].exists)
    }

    // requires verified app AND valid contact with name "Test"
    func testComposeMessageFingerprintExitNavigation() {
        app.navigationBars["Conversations"].buttons["Compose"].tap()
        app.tables.staticTexts["Test"].tap()
        app.navigationBars["Test"].staticTexts["Test"].press(forDuration: 1.0)
        app.buttons["×"].tap()

        XCTAssert(!app.staticTexts["Your Fingerprint"].exists)
    }

    // requires verified app AND valid contact with name "Test"
    func testComposeMessageFingerprintSessionAlert() {
        app.navigationBars["Conversations"].buttons["Compose"].tap()
        app.tables.staticTexts["Test"].tap()
        app.navigationBars["Test"].staticTexts["Test"].press(forDuration: 1.0)
        app.staticTexts["Your Fingerprint"].press(forDuration: 1.5)

        XCTAssert(app.buttons["Reset this session."].exists)
    }

    // requires verified app AND valid contact with name "Test"
    func testComposeMessageFingerprintDisplayNavigation() {
        app.navigationBars["Conversations"].buttons["Compose"].tap()
        app.tables.staticTexts["Test"].tap()
        app.navigationBars["Test"].staticTexts["Test"].press(forDuration: 1.0)
        app.staticTexts["Your Fingerprint"].tap()

        XCTAssert(app.buttons["quit"].exists)
    }

    // requires verified app AND valid contact with name "Test"
    func testComposeMessageFingerprintDisplayExitNavigation() {
        app.navigationBars["Conversations"].buttons["Compose"].tap()
        app.tables.staticTexts["Test"].tap()
        app.navigationBars["Test"].staticTexts["Test"].press(forDuration: 1.0)
        app.staticTexts["Your Fingerprint"].tap()
        app.buttons["quit"].tap()

        XCTAssert(!app.buttons["quit"].exists)
    }

    // requires verified app AND valid contact with name "Test"
    func testConversationExitNavigation() {
        app.staticTexts["Test"].tap()
        app.buttons.element(boundBy: 0).tap()

        XCTAssert(app.buttons["Inbox"].exists)
    }

    // requires verified app AND valid contact with name "Test"
    func testConversationsSwipe() {
        app.staticTexts["Test"].swipeLeft()

        XCTAssert(app.buttons["Delete"].exists)
        XCTAssert(app.buttons["Archive"].exists)
    }

    // requires verified app
    func testComposeMessageNewGroupNavigation() {
        app.navigationBars["Conversations"].buttons["Compose"].tap()
        app.navigationBars["New Message"].buttons["btnGroup  white"].tap()

        XCTAssert(app.navigationBars["New Group"].exists)
    }

    // requires verified app
    func testComposeMessagNewGroupPictureAlert() {
        app.navigationBars["Conversations"].buttons["Compose"].tap()
        app.navigationBars["New Message"].buttons["btnGroup  white"].tap()
        app.buttons["empty group avatar"].tap()

        XCTAssert(app.buttons["Take a Picture"].exists)
    }

    // requires verified app
    // THIS TEST SOMETIMES CRASHES MIDWAY DUE TO INHERENT ISSUE WITH SIGNAL'S
    // GROUP CREATION
    func testComposeMessageNewGroupCreate() {
        app.navigationBars["Conversations"].buttons["Compose"].tap()
        app.navigationBars["New Message"].buttons["btnGroup  white"].tap()
        app.buttons["add conversation"].tap()

        XCTAssert(app.alerts["Creating group"].exists)

        XCTAssert(app.tables.staticTexts["New Group"].exists)
    }

    // requires verified app
    // THIS TEST SOMETIMES CRASHES MIDWAY DUE TO INHERENT ISSUE WITH SIGNAL'S
    // GROUP CREATION
    func testComposeMessageNewGroupCreateDelete() {
        app.navigationBars["Conversations"].buttons["Compose"].tap()
        app.navigationBars["New Message"].buttons["btnGroup  white"].tap()
        app.buttons["add conversation"].tap()
        app.buttons.element(boundBy: 0).tap()
        app.staticTexts["New Group"].swipeLeft()
        app.tables.buttons["Delete"].tap()

        XCTAssert(app.staticTexts["Leaving group"].exists)
    }

    // requires verified app
    func testGroupContactOptionsAction() {
        app.navigationBars["Conversations"].buttons["Compose"].tap()
        app.navigationBars["New Message"].buttons["btnGroup  white"].tap()
        app.buttons["add conversation"].tap()
        app.tables.staticTexts["New Group"].tap()
        app.navigationBars["New Group"].buttons["contact options action"].tap()

        XCTAssert(app.buttons["Update"].exists)
        XCTAssert(app.buttons["Leave"].exists)
        XCTAssert(app.buttons["Members"].exists)
    }

    // requires verified app
    func testGroupContactOptionsUpdateAction() {
        app.navigationBars["Conversations"].buttons["Compose"].tap()
        app.navigationBars["New Message"].buttons["btnGroup  white"].tap()
        app.buttons["add conversation"].tap()
        app.tables.staticTexts["New Group"].tap()
        app.navigationBars["New Group"].buttons["contact options action"].tap()
        app.toolbars.buttons["Update"].tap()

        XCTAssert(app.tables["Add people"].exists)
    }

    // requires verified app
    func testGroupContactOptionsMembersAction() {
        app.navigationBars["Conversations"].buttons["Compose"].tap()
        app.navigationBars["New Message"].buttons["btnGroup  white"].tap()
        app.buttons["add conversation"].tap()
        app.tables.staticTexts["New Group"].tap()
        app.navigationBars["New Group"].buttons["contact options action"].tap()
        app.toolbars.buttons["Members"].tap()

        XCTAssert(app.tables.staticTexts["Group Members:"].exists)
    }

    // requires verified app
    func testGroupContactOptionsLeaveAction() {
        app.navigationBars["Conversations"].buttons["Compose"].tap()
        app.navigationBars["New Message"].buttons["btnGroup  white"].tap()
        app.buttons["add conversation"].tap()
        app.tables.staticTexts["New Group"].tap()
        app.navigationBars["New Group"].buttons["contact options action"].tap()
        app.toolbars.buttons["Leave"].tap()

        XCTAssert(app.staticTexts["You have left the group."].exists)
    }

    // requires verified app AND valid contact with name "Test"
    func testComposeMessageContactSearch() {
        app.navigationBars["Conversations"].buttons["Compose"].tap()
        let searchField = app.tables.searchFields["Search by name or number"]
        searchField.tap()
        app.typeText("Tes")

        XCTAssert(app.tables.staticTexts["Test"].exists)
    }

    // requires verified app AND valid contact with name "Test"
    func testComposeMessageContactSearchSelect() {
        app.navigationBars["Conversations"].buttons["Compose"].tap()
        app.tables.searchFields["Search by name or number"].tap()
        app.typeText("Tes")


// FIXME swift syntax upgrade
//        app.tables.staticTexts["Test"].coordinate(withNormalizedOffset: CGVectorMake(0.0, 0.0)).tap()

        XCTAssert(app.navigationBars["Test"].exists)
    }

    // requires verified app AND valid contact with name "Test"
    func testInboxConversationArchive() {
        app.buttons["Inbox"].tap()
        app.navigationBars["Conversations"].buttons["Compose"].tap()
        app.staticTexts["Test"].tap()
        app.textViews.element(boundBy: app.textViews.count - 1).tap()
        app.textViews.element(boundBy: app.textViews.count - 1).typeText("1")
        app.toolbars.buttons["Send"].tap()
        app.buttons.element(boundBy: 0).tap()
        app.staticTexts["Test"].swipeLeft()
        app.tables.buttons["Archive"].tap()

        XCTAssert(!app.tables.cells["Test"].exists)
    }

    // requires verified app AND valid contact with name "Test"
    func testInboxConversationDelete() {
        app.buttons["Inbox"].tap()
        app.navigationBars["Conversations"].buttons["Compose"].tap()
        app.staticTexts["Test"].tap()
        app.textViews.element(boundBy: app.textViews.count - 1).tap()
        app.textViews.element(boundBy: app.textViews.count - 1).typeText("1")
        app.toolbars.buttons["Send"].tap()
        app.buttons.element(boundBy: 0).tap()
        app.staticTexts["Test"].swipeLeft()
        app.tables.buttons["Delete"].tap()

        XCTAssert(!app.tables.cells["Test"].exists)
    }

    // requires verified app AND valid contact with name "Test"
    func testArchiveConversationUnarchive() {
        app.buttons["Inbox"].tap()
        app.navigationBars["Conversations"].buttons["Compose"].tap()
        app.staticTexts["Test"].tap()
        app.textViews.element(boundBy: app.textViews.count - 1).tap()
        app.textViews.element(boundBy: app.textViews.count - 1).typeText("1")
        app.toolbars.buttons["Send"].tap()
        app.buttons.element(boundBy: 0).tap()
        app.staticTexts["Test"].swipeLeft()
        app.tables.buttons["Archive"].tap()
        app.buttons["Archive"].tap()
        app.staticTexts["Test"].swipeLeft()
        app.tables.buttons["Unarchive"].tap()

        XCTAssert(!app.tables.cells["Test"].exists)
    }

    // requires verified app AND valid contact with name "Test"
    func testArchiveConversationDelete() {
        app.buttons["Inbox"].tap()
        app.navigationBars["Conversations"].buttons["Compose"].tap()
        app.staticTexts["Test"].tap()
        app.textViews.element(boundBy: app.textViews.count - 1).tap()
        app.textViews.element(boundBy: app.textViews.count - 1).typeText("1")
        app.toolbars.buttons["Send"].tap()
        app.buttons.element(boundBy: 0).tap()
        app.staticTexts["Test"].swipeLeft()
        app.tables.buttons["Archive"].tap()
        app.buttons["Archive"].tap()
        app.staticTexts["Test"].swipeLeft()
        app.tables.buttons["Delete"].tap()

        XCTAssert(!app.tables.cells["Test"].exists)
    }

    // requires verified app AND valid contact with name "Test"
    func testSettingsPrivacyClearHistory() {
        app.buttons["Inbox"].tap()
        app.navigationBars["Conversations"].buttons["Compose"].tap()
        app.staticTexts["Test"].tap()
        app.textViews.element(boundBy: app.textViews.count - 1).tap()
        app.textViews.element(boundBy: app.textViews.count - 1).typeText("1")
        app.toolbars.buttons["Send"].tap()
        app.buttons.element(boundBy: 0).tap()
        app.buttons["settings"].tap()
        app.tables.staticTexts["Privacy"].tap()
        app.tables.staticTexts["Clear History Logs"].tap()
        app.buttons["I'm sure."].tap()
        app.buttons["Settings"].tap()
        app.buttons["Done"].tap()

        XCTAssert(!app.staticTexts["Test"].exists)
    }

    // requires verified app
    func testSettingsAdvancedEnableDebugLog() {
        app.buttons["settings"].tap()
        app.tables.staticTexts["Advanced"].tap()
        // FIXME swift syntax upgrade
//        app.switches.element(boundBy: 0).coordinateWithNormalizedOffset(CGVectorMake(0, 0)).press(forDuration: 0, thenDragTo: app.switches.element(boundBy: 0).coordinateWithNormalizedOffset(CGVectorMake(1, 0)))

        XCTAssert(app.tables.staticTexts["Submit Debug Log"].exists)
    }

    // requires verified app
    func testSettingsAdvancedDisableDebugLog() {
        app.buttons["settings"].tap()
        app.tables.staticTexts["Advanced"].tap()
//        app.switches.element(boundBy: 0).coordinateWithNormalizedOffset(CGVectorMake(0, 0)).pressForDuration(0, thenDragToCoordinate: app.switches.elementBoundByIndex(0).coordinate(withNormalizedOffset: CGVectorMake(-1, 0)))

        XCTAssert(!app.tables.staticTexts["Submit Debug Log"].exists)
    }

    // requires verified app
    func testSettingsAdvancedSubmitDebugLog() {
        app.buttons["settings"].tap()
        app.tables.staticTexts["Advanced"].tap()
        app.switches["Enable Debug Log"].swipeLeft()
        app.tables.staticTexts["Submit Debug Log"].tap()

        XCTAssert(app.staticTexts["Sending debug log ..."].exists)

        expectation(for: Predicate(format: "exists == true"), evaluatedWith: app.alerts["Submit Debug Log"], handler: nil)
        waitForExpectations(withTimeout: 5, handler: nil)

        XCTAssert(app.alerts["Submit Debug Log"].exists)
    }

    // requires verified app
    func testSettingsAdvancedReRegisterForPushNotifications() {
        app.buttons["settings"].tap()
        app.tables.staticTexts["Advanced"].tap()
        app.tables.staticTexts["Re-register for push notifications"].tap()

        XCTAssert(app.alerts["Push Notifications"].exists)
    }

    // requires verified app
    func testSettingsNotificationsOptionsPreview() {
        app.buttons["settings"].tap()
        app.tables.staticTexts["Notifications"].tap()
        app.tables.staticTexts["Show"].tap()
        app.tables.staticTexts["Sender name & message"].tap()

        XCTAssert(app.staticTexts["Sender name & message"].exists)
    }

}

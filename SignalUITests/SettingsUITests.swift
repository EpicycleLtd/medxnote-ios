//
//  SettingsUITests.swift
//  Signal
//
//  Created by Michael Kirk on 4/1/16.
//  Copyright © 2016 Open Whisper Systems. All rights reserved.
//

import XCTest

class SettingsUITests: UITestCase {

    override func setUp() {
        super.setUp()
        app.launchArguments = [TSRunTestSetup, TSStartingStateForTestRegistered]
        app.launch()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testSettingsNavigation() {
        app.navigationBars["Conversations"].buttons["settings"].tap()

        XCTAssert(app.staticTexts["Settings"].exists)

        app.navigationBars["Settings"].buttons["Done"].tap()

        XCTAssert(app.buttons["Inbox"].exists)
    }

    func testSettingsPrivacyNavigation() {
        app.navigationBars["Conversations"].buttons["settings"].tap()
        app.tables.staticTexts["Privacy"].tap()

        XCTAssert(app.navigationBars["Privacy"].exists)
    }

    func testSettingsPrivacyClearHistoryLogAlert() {
        app.navigationBars["Conversations"].buttons["settings"].tap()
        let tablesQuery = app.tables
        tablesQuery.staticTexts["Privacy"].tap()
        tablesQuery.staticTexts["Clear History Logs"].tap()


        XCTAssert(app.staticTexts["Are you sure you want to delete all your history (messages, attachments, call history ...) ? This action cannot be reverted."].exists)
    }

    func testSettingsNotificationsNavigation() {
        app.navigationBars["Conversations"].buttons["settings"].tap()
        app.tables.staticTexts["Notifications"].tap()

        XCTAssert(app.navigationBars["Notifications"].exists)
    }

    func testSettingsNotificationsOptionsNavigation() {
        app.navigationBars["Conversations"].buttons["settings"].tap()
        app.tables.staticTexts["Notifications"].tap()
        app.tables.staticTexts["Show"].tap()

        XCTAssert(app.navigationBars["NotificationSettingsOptionsView"].exists)
    }

    func testSettingsAdvancedNavigation() {
        app.navigationBars["Conversations"].buttons["settings"].tap()
        app.tables.staticTexts["Advanced"].tap()

        XCTAssert(app.navigationBars["Advanced"].exists)
    }

    func testSettingsAboutNavigation() {
        app.navigationBars["Conversations"].buttons["settings"].tap()
        app.tables.staticTexts["About"].tap()

        XCTAssert(app.navigationBars["About"].exists)
    }

    func testSettingsDeleteAccountAlert() {
        app.navigationBars["Conversations"].buttons["settings"].tap()
        app.tables.buttons["Delete Account"].tap()
        
        XCTAssert(app.alerts["Are you sure you want to delete your account?"].exists)
    }

}

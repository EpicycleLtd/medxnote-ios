//
//  TSUITest.swift
//  Signal
//
//  Created by Michael Kirk on 4/1/16.
//  Copyright © 2016 Open Whisper Systems. All rights reserved.
//

import XCTest

class UITestCase: XCTestCase {
    
    let app = XCUIApplication()
    
    override func setUp() {
        super.setUp()
        acceptAnyPermissionDialog()
        self.continueAfterFailure = false
    }

    override func tearDown() {
        //Is this necessary?
        XCUIApplication().launchArguments = []
        super.tearDown()
    }

    func acceptAnyPermissionDialog() {
        addUIInterruptionMonitor(withDescription: "Permissions Handler") { (alert) -> Bool in
            if (alert.staticTexts["“Signal” Would Like to Send You Notifications"].exists) {
                alert.buttons["Allow"].tap()
                NSLog("Authorized Notifications permission.")
                return true
            } else if (alert.staticTexts["“Signal” Would Like to Access Your Contacts"].exists) {
                alert.buttons["OK"].tap()
                NSLog("Authorized Notifications permission.")
                return true
            }
            return false
        }
    }
}

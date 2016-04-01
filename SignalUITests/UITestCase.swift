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
        self.continueAfterFailure = false
    }

    override func tearDown() {
        //Is this necessary?
        XCUIApplication().launchArguments = []
        super.tearDown()
    }
}
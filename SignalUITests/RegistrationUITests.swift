//
//  SignalUITests.swift
//  SignalUITests
//
//  Created by Matthew Kotila on 1/13/16.
//  Copyright © 2016 Open Whisper Systems. All rights reserved.
//

import XCTest

class RegistrationUITests: UITestCase {
    
    override func setUp() {
        super.setUp()
        app.launchArguments = [TSRunTestSetup, TSStartingStateForTestUnregistered]
        app.launch()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func DISABLED_testCountryCodeSelectionScreenStandardSelect() {
        app.buttons["Country Code"].tap()
        app.tables.staticTexts["Bahrain"].tap()

        // TEST DISABLED because implicit scrolling is broken in XCode8 Beta
        XCTAssert(app.buttons["Bahrain"].exists)
        XCTAssert(app.buttons["+33"].exists)
    }

    func testCountryCodeSelectionScreenSearch() {
        app.buttons["Country Code"].tap()

        XCTAssert(app.staticTexts["Afghanistan"].exists)
        let searchField = app.tables.children(matching: .searchField).element
        searchField.tap()
        searchField.typeText("Fran")
        XCTAssert(app.staticTexts["France"].exists)
        XCTAssert(!app.staticTexts["Afghanistan"].exists)

        app.tables.staticTexts["France"].tap()

        XCTAssert(app.buttons["France"].exists)
        XCTAssert(app.buttons["+33"].exists)
    }

    func testCountryCodeSelectionScreenBackNavigation() {
        app.buttons["Country Code"].tap()
        app.navigationBars["Select Country Code"].buttons["btnCancel  white"].tap()

        XCTAssert(app.staticTexts["Your Phone Number"].exists)
    }

    func testVerifyUnsupportedPhoneNumberAlert() {
        app.buttons["Verify This Device"].tap()

        let alert = app.alerts["Registration Error"]
        expectation(for: Predicate(format: "exists == 1"), evaluatedWith: alert, handler: nil)
        waitForExpectations(withTimeout: 5, handler: nil)
    }

    func testVerifySupportedPhoneNumberChangeNumberNavigation() {
        app.textFields["Enter Number"].typeText("5555555555")
        app.buttons["Verify This Device"].tap()
        app.buttons["     Change Number"].tap()
        
        XCTAssert(app.staticTexts["Your Phone Number"].exists)
    }
}

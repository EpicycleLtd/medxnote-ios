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

    func testCountryCodeSelectionScreenNavigation() {
        app.buttons["Country Code"].tap()
        
        XCTAssert(app.staticTexts["Select Country Code"].exists)
    }

    func testCountryCodeSelectionScreenBackNavigation() {
        app.buttons["Country Code"].tap()
        app.navigationBars["Select Country Code"].buttons["btnCancel  white"].tap()
        
        XCTAssert(app.staticTexts["Your Phone Number"].exists)
    }

    func testCountryCodeSelectionScreenSearch() {
        app.buttons["Country Code"].tap()
        let searchField = app.tables.childrenMatchingType(.SearchField).element
        searchField.tap()
        searchField.typeText("Fran")
        
        XCTAssert(app.staticTexts["France"].exists)
    }

    func testCountryCodeSelectionScreenStandardSelect() {
        app.buttons["Country Code"].tap()
        app.tables.staticTexts["France"].tap()
        
        XCTAssert(app.buttons["France"].exists)
        XCTAssert(app.buttons["+33"].exists)
    }

    func testCountryCodeSelectionScreenSearchSelect() {
        app.buttons["Country Code"].tap()
        let searchField = app.tables.childrenMatchingType(.SearchField).element
        searchField.tap()
        searchField.typeText("Fran")
        app.tables.staticTexts["France"].tap()
        
        XCTAssert(app.buttons["France"].exists)
        XCTAssert(app.buttons["+33"].exists)
    }

    func testVerifyUnsupportedPhoneNumberAlert() {
        app.buttons["Verify This Device"].tap()
        
        XCTAssert(app.alerts["Registration Error"].exists)
    }

    func testVerifySupportedPhoneNumberChangeNumberNavigation() {
        app.textFields["Enter Number"].typeText("5555555555")
        app.buttons["Verify This Device"].tap()
        app.buttons["     Change Number"].tap()
        
        XCTAssert(app.staticTexts["Your Phone Number"].exists)
    }
}

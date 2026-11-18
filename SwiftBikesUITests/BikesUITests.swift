//
//  BikesUITests.swift
//  SwiftBikesUITests
//
//  Created by Martin Davy on 7/10/18.
//  Copyright © 2018 Martin Davy. All rights reserved.
//

import XCTest

@MainActor
final class BikesUITests: XCTestCase {

    override func setUp() async throws {
        continueAfterFailure = false
    }

    /// Guards against the app failing to present a window at launch (for example a
    /// missing UIScene configuration, which newer SDKs treat as a launch failure).
    func testLaunchShowsMapAndControls() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.maps.firstMatch.waitForExistence(timeout: 15))
        XCTAssertTrue(app.buttons["Nearest available bike"].exists)
        XCTAssertTrue(app.buttons["Nearest available dock"].exists)
        XCTAssertTrue(app.buttons["Follow my location"].exists)
    }
}

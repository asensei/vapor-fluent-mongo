//
//  LinuxMain.swift
//  FluentMongoTests
//
//  Created by Valerio Mazzeo on 18/12/2018.
//  Copyright © 2018 Asensei Inc. All rights reserved.
//

#if os(Linux)

import XCTest
@testable import FluentMongoTests

XCTMain([
    testCase(FluentMongoProviderTests.allTests)
])

#endif

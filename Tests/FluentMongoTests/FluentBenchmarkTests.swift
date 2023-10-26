//
//  FluentBenchmarkTests.swift
//  FluentMongoTests
//
//  Created by Valerio Mazzeo on 21/10/2019.
//  Copyright © 2019 Asensei Inc. All rights reserved.
//

import XCTest
import NIO
import Logging
import FluentBenchmark
import FluentKit
import MongoSwift
@testable import FluentMongo

final class FluentBenchmarkTests: XCTestCase {

    var benchmarker: FluentBenchmarker {
        return .init(databases: self.dbs)
    }
    var eventLoopGroup: EventLoopGroup!
    var threadPool: NIOThreadPool!
    var dbs: Databases!
    var db: Database {
        self.benchmarker.database
    }
    var mongo: FluentMongo.MongoDatabase {
        self.db as! FluentMongo.MongoDatabase
    }

    override func setUpWithError() throws {
        try super.setUpWithError()

        XCTAssert(isLoggingConfigured)
        self.eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        self.threadPool = NIOThreadPool(numberOfThreads: System.coreCount)
        self.dbs = Databases(threadPool: self.threadPool, on: self.eventLoopGroup)

        try clearDatabase("\(mongoConnectionString)/vapor_database", on: self.eventLoopGroup)
        try clearDatabase("\(mongoConnectionString)/vapor-migration-extra", on: self.eventLoopGroup)

        try self.dbs.use(.mongo(connectionString: "\(mongoConnectionString)/vapor_database"), as: .mongo)
        try self.dbs.use(.mongo(connectionString: "\(mongoConnectionString)/vapor-migration-extra"), as: .migrationExtra)
    }

    override func tearDownWithError() throws {
        self.dbs.shutdown()
        try self.threadPool.syncShutdownGracefully()
        try self.eventLoopGroup.syncShutdownGracefully()

        try super.tearDownWithError()
    }

    func testAggregate() throws { try self.benchmarker.testAggregate() }
    func testArray() throws { try self.benchmarker.testArray() }
    func testBatch() throws { try self.benchmarker.testBatch() }
    func testChildren() throws { try self.benchmarker.testChildren() }
    func testCodable() throws { try self.benchmarker.testCodable() }
    func testChunk() throws { try self.benchmarker.testChunk() }
    func testCompositeID() throws { try self.benchmarker.testCompositeID() }
    func testCRUD() throws { try self.benchmarker.testCRUD() }
    func testEagerLoad() throws { try self.benchmarker.testEagerLoad() }
    func testEnum() throws { try self.benchmarker.testEnum() }
    func testFilter() throws { try self.benchmarker.testFilter(sql: false) }
    func testGroup() throws { try self.benchmarker.testGroup() }
    func testID() throws { try self.benchmarker.testID(autoincrement: false, custom: false) }
    func testJoin() throws { try self.benchmarker.testJoin() }
    func testMiddleware() throws { try self.benchmarker.testMiddleware() }
    func testMigrator() throws { try self.benchmarker.testMigrator() }
    func testModel() throws { try self.benchmarker.testModel() }
    func testOptionalParent() throws { try self.benchmarker.testOptionalParent() }
    func testPagination() throws { try self.benchmarker.testPagination() }
    func testParent() throws { try self.benchmarker.testParent() }
    func testPerformance() throws { try self.benchmarker.testPerformance(decimalType: .dictionary) }
    func testRange() throws { try self.benchmarker.testRange() }
    func testSchema() throws { try self.benchmarker.testSchema(foreignKeys: false) }
    func testSet() throws { try self.benchmarker.testSet() }
    func testSiblings() throws { try self.benchmarker.testSiblings() }
    func testSoftDelete() throws { try self.benchmarker.testSoftDelete() }
    func testSort() throws { try self.benchmarker.testSort(sql: false) }
    func testTimestamp() throws { try self.benchmarker.testTimestamp() }
    func testTransaction() throws {
        #if os(Linux)
        try self.benchmarker.testTransaction()
        #endif
    }
    func testUnique() throws { try self.benchmarker.testUnique() }
}

func env(_ name: String) -> String? {
    return ProcessInfo.processInfo.environment[name]
}

let mongoConnectionString: String = {
    #if os(Linux)

    return "mongodb://0.0.0.0:27001,0.0.0.0:27002,0.0.0.0:27003"
    #else

    return "mongodb://localhost:27017"
    #endif
}()

func clearDatabase(_ connectionString: String, on eventLoopGroup: EventLoopGroup) throws {

    let client = try MongoClient(connectionString, using: eventLoopGroup)

    try client
        .db(connectionString.components(separatedBy: "/").last ?? "")
        .drop()
        .wait()

    try client.syncClose()
}

let isLoggingConfigured: Bool = {
    LoggingSystem.bootstrap { label in
        var handler = StreamLogHandler.standardOutput(label: label)
        handler.logLevel = .debug

        return handler
    }
    return true
}()

extension DatabaseID {
    static let migrationExtra = DatabaseID(string: "migration-extra")
}

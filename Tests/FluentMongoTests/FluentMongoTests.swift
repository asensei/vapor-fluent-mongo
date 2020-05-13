//
//  FluentMongoTests.swift
//  FluentMongoTests
//
//  Created by Valerio Mazzeo on 21/10/2019.
//  Copyright © 2019 Asensei Inc. All rights reserved.
//

import XCTest
import NIO
import AsyncKit
import FluentBenchmark
import FluentMongo
import Logging
import MongoSwift

/*
final class FluentMongoTests: XCTestCase {

    func testAll() throws {
        try self.benchmarker.testAll()
    }

    func testCreate() throws {
        try self.benchmarker.testCreate()
    }

    func testRead() throws {
        try self.benchmarker.testRead()
    }

    func testUpdate() throws {
        try self.benchmarker.testUpdate()
    }

    func testDelete() throws {
        try self.benchmarker.testDelete()
    }

    func testEagerLoadChildren() throws {
        try self.benchmarker.testEagerLoadChildren()
    }

    func testEagerLoadParent() throws {
        try self.benchmarker.testEagerLoadParent()
    }

    func testEagerLoadParentJoin() throws {
        try self.benchmarker.testEagerLoadParentJoin()
    }

    func testEagerLoadParentJSON() throws {
        try self.benchmarker.testEagerLoadParentJSON()
    }

    func testEagerLoadChildrenJSON() throws {
        try self.benchmarker.testEagerLoadChildrenJSON()
    }

    func testMigrator() throws {
        try self.benchmarker.testMigrator()
    }

    func testMigratorError() throws {
        try self.benchmarker.testMigratorError()
    }

    func testJoin() throws {
        try self.benchmarker.testJoin()
    }

    func testBatchCreate() throws {
        try self.benchmarker.testBatchCreate()
    }

    func testBatchUpdate() throws {
        try self.benchmarker.testBatchUpdate()
    }

    func testNestedModel() throws {
        try self.benchmarker.testNestedModel()
    }

    func testAggregates() throws {
        try self.benchmarker.testAggregates()
    }

    func testIdentifierGeneration() throws {
        try self.benchmarker.testIdentifierGeneration()
    }

    func testNullifyField() throws {
        try self.benchmarker.testNullifyField()
    }

    func testChunkedFetch() throws {
        try self.benchmarker.testChunkedFetch()
    }

    func testUniqueFields() throws {
        try self.benchmarker.testUniqueFields()
    }

    func testAsyncCreate() throws {
        try self.benchmarker.testAsyncCreate()
    }

    func testSoftDelete() throws {
        try self.benchmarker.testSoftDelete()
    }

    func testTimestampable() throws {
        try self.benchmarker.testTimestampable()
    }

    func testLifecycleHooks() throws {
        try self.benchmarker.testLifecycleHooks()
    }

    func testSort() throws {
        try self.benchmarker.testSort()
    }

    func testUUIDModel() throws {
        try self.benchmarker.testUUIDModel()
    }

    func testNewModelDecode() throws {
        try self.benchmarker.testNewModelDecode()
    }

    func testSiblingsAttach() throws {
        try self.benchmarker.testSiblingsAttach()
    }

    func testParentGet() throws {
        try self.benchmarker.testParentGet()
    }

    func testParentSerialization() throws {
        try self.benchmarker.testParentSerialization()
    }

    func testSiblingsEagerLoad() throws {
        try self.benchmarker.testSiblingsEagerLoad()
    }

    func testMultipleJoinSameTable() throws {
        try self.benchmarker.testMultipleJoinSameTable()
    }

    func testOptionalParent() throws {
        try self.benchmarker.testOptionalParent()
    }

    var benchmarker: FluentBenchmarker {
        return .init(database: self.dbs.default())
    }
    var threadPool: NIOThreadPool!
    var eventLoopGroup: EventLoopGroup!
    var dbs: Databases!

    override func setUp() {
        XCTAssert(isLoggingConfigured)
        self.eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        self.threadPool = .init(numberOfThreads: 2)

        let configuration = try! MongoConfiguration(
            host: "localhost",
            port: 27017,
            database: "vapor_database"
        )

        try? MongoClient(configuration.connectionURL.absoluteString).db(configuration.database).drop()

        self.dbs = Databases()
        self.dbs.mongo(
            configuration: configuration,
            threadPool: self.threadPool,
            poolConfiguration: .init(maxConnections: 8),
            on: self.eventLoopGroup
        )
    }

    override func tearDown() {
        self.dbs.shutdown()
        self.dbs = nil
        try! self.threadPool.syncShutdownGracefully()
        self.threadPool = nil
        try! self.eventLoopGroup.syncShutdownGracefully()
        self.eventLoopGroup = nil
    }
}

let isLoggingConfigured: Bool = {
    LoggingSystem.bootstrap { label in
        var handler = StreamLogHandler.standardOutput(label: label)
        handler.logLevel = .debug
        return handler
    }
    return true
}()
*/
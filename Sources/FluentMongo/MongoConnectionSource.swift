//
//  MongoConnectionSource.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 22/10/2019.
//  Copyright © 2019 Asensei Inc. All rights reserved.
//

import Foundation
import NIO
import AsyncKit
import FluentKit
/*
public struct MongoConnectionSource: ConnectionPoolSource {

    // MARK: Initialization

    public init(
        configuration: MongoConfiguration,
        threadPool: NIOThreadPool,
        logger: Logger = .init(label: "vapor.fluent.mongo.connection-source")
    ) {
        self.configuration = configuration
        self.threadPool = threadPool
        self.logger = logger
    }

    // MARK: Managing Connection Source

    private let configuration: MongoConfiguration

    private let threadPool: NIOThreadPool

    private let logger: Logger

    // MARK: ConnectionPoolSource

    public func makeConnection(on eventLoop: EventLoop) -> EventLoopFuture<MongoConnection> {
        return MongoConnection.connect(
            to: self.configuration.connectionURL.absoluteString,
            database: self.configuration.database,
            options: self.configuration.options,
            threadPool: threadPool,
            on: eventLoop
        )
    }
}
*/
//
//  MongoConnection.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 21/10/2019.
//  Copyright © 2019 Asensei Inc. All rights reserved.
//

import Foundation
import AsyncKit
import MongoSwift

public final class MongoConnection: ConnectionPoolItem {

    public static func connect(
        to connectionString: String,
        database: String,
        options: ClientOptions? = nil,
        logger: Logger = .init(label: "vapor.fluent.mongo.connection"),
        on eventLoop: EventLoop
    ) -> EventLoopFuture<MongoConnection> {

        let promise = eventLoop.makePromise(of: MongoConnection.self)

        do {
            let connection = MongoConnection(
                client: try MongoClient(connectionString, using: eventLoop, options: options),
                database: database,
                logger: logger,
                on: eventLoop
            )

            logger.debug("Connected to mongo db: \(database)")
            promise.succeed(connection)
        } catch {
            logger.error("Failed to connect to mongo db: \(database). \(error.localizedDescription)")
            promise.fail(error)
        }

        return promise.futureResult
    }

    // MARK: Initialization

    init(
        client: MongoClient,
        database: String,
        logger: Logger,
        on eventLoop: EventLoop
    ) {
        self.client = client
        self.database = database
        self.logger = logger
        self.eventLoop = eventLoop
    }

    // MARK: Accessing Attributes

    public let database: String

    public let eventLoop: EventLoop

    // MARK: Managing Connection

    private let client: MongoClient

    private let logger: Logger

    // MARK: ConnectionPoolItem

    public private(set) var isClosed: Bool = false

    public func close() -> EventLoopFuture<Void> {
        self.client.close().always { result in
            switch result {
            case .success:
                self.isClosed = true
            default:
                break
            }
        }
    }
}

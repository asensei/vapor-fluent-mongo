//
//  MongoConnection.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 21/10/2019.
//  Copyright © 2019 Asensei Inc. All rights reserved.
//

import Foundation
import AsyncKit
import Logging
import MongoSwift
//import protocol FluentKit.DatabaseRow // TODO: Review if we can avoid having this dependency here

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

public typealias MongoCommand = MongoDocument

extension MongoConnection {

    public func execute(_ closure: @escaping (MongoDatabase) throws -> [DatabaseRow]) -> EventLoopFuture<[DatabaseRow]> {
        var results: [DatabaseRow] = []
        return self.execute(closure) { result in
            results.append(result)
        }.map { results }
    }

    public func execute(_ closure: @escaping (MongoDatabase) throws -> [DatabaseRow], _ onRow: @escaping (DatabaseRow) -> Void) -> EventLoopFuture<Void> {

        let promise = self.eventLoop.makePromise(of: Void.self)

        self.threadPool.submit { _ in
            do {
                let database = self.client.db(self.database)
                let results = try closure(database)

                guard !results.isEmpty else {
                    return promise.succeed(Void())
                }

                var callbacks: [EventLoopFuture<Void>] = []
                for result in results {
                    let callback = self.eventLoop.submit {
                        onRow(result)
                    }
                    callbacks.append(callback)
                }

                EventLoopFuture<Void>
                    .andAllComplete(callbacks, on: self.eventLoop)
                    .cascade(to: promise)
            } catch {
                promise.fail(error)
            }
        }

        return promise.futureResult
    }
}

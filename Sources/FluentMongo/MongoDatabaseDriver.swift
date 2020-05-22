//
//  MongoDatabaseDriver.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 22/10/2019.
//  Copyright © 2019 Asensei Inc. All rights reserved.
//

import Foundation
import AsyncKit
import FluentKit

// MARK: - MongoDatabaseDriver

struct MongoDatabaseDriver {

    // MARK: Initialization

    public init(
        pool: EventLoopGroupConnectionPool<MongoConnectionSource>,
        encoder: BSONEncoder = BSONEncoder(),
        decoder: BSONDecoder = BSONDecoder()
    ) {
        self.pool = pool
        self.encoder = encoder
        self.decoder = decoder
    }

    // MARK: Accessing Attributes

    let pool: EventLoopGroupConnectionPool<MongoConnectionSource>

    let encoder: BSONEncoder

    let decoder: BSONDecoder
}

extension MongoDatabaseDriver: DatabaseDriver {

    var eventLoopGroup: EventLoopGroup {
        return self.pool.eventLoopGroup
    }

    func makeDatabase(with context: DatabaseContext) -> Database {
        FluentMongoDatabase(
            database: ConnectionPoolMongoDatabase(
                pool: self.pool.pool(for: context.eventLoop),
                logger: context.logger
            ),
            context: context,
            session: nil,
            encoder: self.encoder,
            decoder: self.decoder
        )
    }

    func shutdown() {
        self.pool.shutdown()
    }
}

// MARK: - ConnectionPoolMongoDatabase

struct ConnectionPoolMongoDatabase: MongoDatabase {

    let pool: EventLoopConnectionPool<MongoConnectionSource>

    let logger: Logger

    var eventLoop: EventLoop {
        self.pool.eventLoop
    }

    func execute(_ closure: @escaping (MongoSwift.MongoDatabase, EventLoop) -> EventLoopFuture<[DatabaseOutput]>, _ onOutput: @escaping (DatabaseOutput) -> Void) -> EventLoopFuture<Void> {
        self.withConnection { connection in
            connection.execute(closure, onOutput)
        }
    }

    func execute<T>(_ closure: @escaping (MongoSwift.MongoDatabase, EventLoop) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        self.withConnection { connection in
            connection.execute(closure)
        }
    }

    func withSession<T>(_ closure: @escaping (ClientSession) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        self.withConnection { connection in
            connection.withSession(closure)
        }
    }

    func withConnection<T>(_ closure: @escaping (MongoConnection) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        self.pool.withConnection(logger: self.logger, closure)
    }
}

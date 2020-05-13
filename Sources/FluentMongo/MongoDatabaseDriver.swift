//
//  MongoDatabaseDriver.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 22/10/2019.
//  Copyright © 2019 Asensei Inc. All rights reserved.
//

import Foundation
import FluentKit
import MongoSwift


/*
struct MongoDatabaseDriver {

    // MARK: Initialization

    public init(
        pool: ConnectionPool<MongoConnectionSource>,
        encoder: BSONEncoder = BSONEncoder(),
        decoder: BSONDecoder = BSONDecoder()
    ) {
        self.pool = pool
        self.encoder = encoder
        self.decoder = decoder
    }

    // MARK: Accessing Attributes

    public let pool: ConnectionPool<MongoConnectionSource>

    let encoder: BSONEncoder

    let decoder: BSONDecoder
}

extension MongoDatabaseDriver: DatabaseDriver {

    public var eventLoopGroup: EventLoopGroup {
        return self.pool.eventLoopGroup
    }

    func execute(query: DatabaseQuery, database: Database, onRow: @escaping (DatabaseRow) -> ()) -> EventLoopFuture<Void> {
        return self.pool.withConnection { connection in
            return connection.execute(MongoQueryConverter(query, using: self.encoder).convert) { document in
                onRow(document)
            }
        }
    }

    func execute(schema: DatabaseSchema, database: Database) -> EventLoopFuture<Void> {
        return self.pool.withConnection { connection in
            return connection.execute(MongoSchemaConverter(schema).convert) { _ in }
        }
    }

    func shutdown() {
        self.pool.shutdown()
    }
}
*/

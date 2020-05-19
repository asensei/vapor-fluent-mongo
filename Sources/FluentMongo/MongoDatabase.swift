//
//  MongoDatabase.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 14/05/2020.
//  Copyright © 2020 Asensei Inc. All rights reserved.
//

import Foundation
import FluentKit
import MongoSwift

protocol MongoDatabase {

    var eventLoop: EventLoop { get }

    var logger: Logger { get }

    func execute(_ closure: @escaping (MongoSwift.MongoDatabase, EventLoop) -> EventLoopFuture<[DatabaseOutput]>, _ onOutput: @escaping (DatabaseOutput) -> Void) -> EventLoopFuture<Void>

    func execute<T>(_ closure: @escaping (MongoSwift.MongoDatabase, EventLoop) -> EventLoopFuture<T>) -> EventLoopFuture<T>

    func withConnection<T>(_ closure: @escaping (MongoConnection) -> EventLoopFuture<T>) -> EventLoopFuture<T>
}

extension MongoDatabase {

    func execute(_ closure: @escaping (MongoSwift.MongoDatabase, EventLoop) -> EventLoopFuture<[DatabaseOutput]>) -> EventLoopFuture<[DatabaseOutput]> {
        var results: [DatabaseOutput] = []

        return self.execute(closure) { result in
            results.append(result)
        }.map { results }
    }
}

struct FluentMongoDatabase: Database {

    let database: MongoDatabase

    let context: DatabaseContext

    let encoder: BSONEncoder

    let decoder: BSONDecoder

    func execute(query: DatabaseQuery, onOutput: @escaping (DatabaseOutput) -> ()) -> EventLoopFuture<Void> {
        return self.database.withConnection { connection in
            return connection.execute(MongoQueryConverter(query, encoder: self.encoder, decoder: self.decoder).convert) { result in
                onOutput(result)
            }
        }
    }

    func execute(schema: DatabaseSchema) -> EventLoopFuture<Void> {
        return self.database.withConnection { connection in
            return connection.execute(MongoSchemaConverter(schema).convert)
        }
    }

    func execute(enum: DatabaseEnum) -> EventLoopFuture<Void> {
        fatalError()
    }

    func transaction<T>(_ closure: @escaping (Database) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        fatalError()
    }

    func withConnection<T>(_ closure: @escaping (Database) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        self.database.withConnection {
            closure(FluentMongoDatabase(
                database: $0,
                context: self.context,
                encoder: self.encoder,
                decoder: self.decoder
            ))
        }
    }
}

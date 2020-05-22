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

    func withSession<T>(_ closure: @escaping (ClientSession) -> EventLoopFuture<T>) -> EventLoopFuture<T>

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

    let session: ClientSession?

    let encoder: BSONEncoder

    let decoder: BSONDecoder

    func execute(query: DatabaseQuery, onOutput: @escaping (DatabaseOutput) -> ()) -> EventLoopFuture<Void> {
        self.database.withConnection { connection in
            connection.execute({ database, eventLoop in
                MongoQueryConverter(query, encoder: self.encoder, decoder: self.decoder).convert(database, session: self.session, on: eventLoop)
            }) { result in
                onOutput(result)
            }
        }
    }

    func execute(schema: DatabaseSchema) -> EventLoopFuture<Void> {
        self.database.withConnection { connection in
            connection.execute { database, eventLoop in
                MongoSchemaConverter(schema).convert(database, session: self.session, on: eventLoop)
            }
        }
    }

    func execute(enum: DatabaseEnum) -> EventLoopFuture<Void> {
        self.eventLoop.makeSucceededFuture(Void())
    }

    func transaction<T>(_ closure: @escaping (Database) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        self.database.withConnection { connection in
            connection.withSession { session in
                session.startTransaction().flatMap {
                    let transactionDatabase = FluentMongoDatabase(
                        database: connection,
                        context: self.context,
                        session: session,
                        encoder: self.encoder,
                        decoder: self.decoder
                    )

                    return closure(transactionDatabase)
                        .flatMap { value in
                            session.commitTransaction().map { value }
                        }
                        .flatMapError { error in
                            session.abortTransaction().flatMapThrowing { throw error }
                        }
                }
            }
        }
    }

    func withConnection<T>(_ closure: @escaping (Database) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        self.database.withConnection { connection in
            closure(FluentMongoDatabase(
                database: connection,
                context: self.context,
                session: nil,
                encoder: self.encoder,
                decoder: self.decoder
            ))
        }
    }
}

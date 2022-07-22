//
//  MongoQueryConverter.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 22/10/2019.
//  Copyright © 2019 Asensei Inc. All rights reserved.
//

import Foundation
import FluentKit
import MongoSwift

struct MongoQueryConverter {

    public init(_ query: DatabaseQuery, encoder: BSONEncoder, decoder: BSONDecoder) {
        self.query = query
        self.encoder = encoder
        self.decoder = decoder
    }

    private let query: DatabaseQuery

    private let encoder: BSONEncoder

    private let decoder: BSONDecoder

    public func convert(_ database: MongoSwift.MongoDatabase, session: ClientSession? = nil, on eventLoop: EventLoop) -> EventLoopFuture<[DatabaseOutput]> {

        let future: EventLoopFuture<[DatabaseOutput]>

        switch self.query.action {
        case .read:
            future = self.find(database, session, on: eventLoop)
        case .create:
            future = self.insert(database, session, on: eventLoop)
        case .update:
            future = self.update(database, session, on: eventLoop)
        case .delete:
            future = self.delete(database, session, on: eventLoop)
        case .aggregate(let value):
            future = self.aggregate(value, database, session, on: eventLoop)
        case .custom(let value as DatabaseQuery.Action.MongoIndex):
            future = self.index(value, database, session, on: eventLoop)
        case .custom(let command as BSONDocument):
            future = self.custom(command, database, session, on: eventLoop)
        case .custom:
            future = eventLoop.makeFailedFuture(Error.unsupportedQueryAction)
        }

        return future
    }
}

extension MongoQueryConverter {

    private func find(_ database: MongoSwift.MongoDatabase, _ session: ClientSession?, on eventLoop: EventLoop) -> EventLoopFuture<[DatabaseOutput]> {

        let collection = database.collection(self.query.schema)

        do {
            let pipeline = try self.aggregationPipeline()

            return collection.aggregate(pipeline, options: nil, session: session).flatMap { cursor in
                cursor.toArray().mapEach { $0.databaseOutput(fields: self.query.fields, using: self.decoder) }
            }
        } catch {
            return eventLoop.makeFailedFuture(error)
        }
    }

    private func aggregate(_ aggregate: DatabaseQuery.Aggregate, _ database: MongoSwift.MongoDatabase, _ session: ClientSession?, on eventLoop: EventLoop) -> EventLoopFuture<[DatabaseOutput]> {
        let collection = database.collection(self.query.schema)

        do {
            let pipeline = try self.aggregationPipeline()

            return collection.aggregate(pipeline, options: nil, session: session).flatMap { cursor in
                cursor.toArray()
                    .flatMapThrowing { $0.isEmpty ? [try aggregate.mongoAggregationEmptyResult()] : $0 }
                    .mapEach { $0.databaseOutput(fields: self.query.fields, using: self.decoder) }
            }
        } catch {
            return eventLoop.makeFailedFuture(error)
        }
    }

    private func insert(_ database: MongoSwift.MongoDatabase, _ session: ClientSession?, on eventLoop: EventLoop) -> EventLoopFuture<[DatabaseOutput]> {
        do {
            let documents = try self.query.input.compactMap { try $0.mongoValueInsert(encoder: self.encoder)?.documentValue }
            let collection = database.collection(self.query.schema)

            return collection.insertMany(documents, session: session).flatMapThrowing { result in
                guard let result = result else {
                    throw Error.invalidResult
                }

                guard documents.count == result.insertedCount else {
                    throw Error.insertManyMismatch(documents.count, result.insertedCount)
                }

                return result.insertedIDs.map {
                    BSONDocument(dictionaryLiteral: (FieldKey.id.mongoKey, $0.value)).databaseOutput(fields: self.query.fields, using: self.decoder)
                }
            }.flatMapErrorThrowing { error in
                switch error {
                case let error as MongoError.WriteError where error.isDuplicatedKeyError:
                    throw Error.duplicatedKey(error.errorDescription ?? "No error description available.")
                case let error as MongoError.BulkWriteError where error.isDuplicatedKeyError:
                    throw Error.duplicatedKey(error.errorDescription ?? "No error description available.")
                default:
                    throw error
                }
            }
        } catch {
            return eventLoop.makeFailedFuture(error)
        }
    }

    private func update(_ database: MongoSwift.MongoDatabase, _ session: ClientSession?, on eventLoop: EventLoop) -> EventLoopFuture<[DatabaseOutput]> {
        do {
            let documents: [BSONDocument] = try self.query.input.compactMap { try $0.mongoValueUpdate(encoder: self.encoder)?.documentValue }

            return self.filter(database, session, on: eventLoop).flatMap { filter in
                let collection = database.collection(self.query.schema)
                let updates = documents.map { document in
                    collection.updateMany(filter: filter, update: document, session: session)
                }.flatten(on: eventLoop)

                return updates.transform(to: [])
            }
        } catch {
            return eventLoop.makeFailedFuture(error)
        }
    }

    private func delete(_ database: MongoSwift.MongoDatabase, _ session: ClientSession?, on eventLoop: EventLoop) -> EventLoopFuture<[DatabaseOutput]> {
        return self.filter(database, session, on: eventLoop).flatMap { filter in
            database.collection(self.query.schema).deleteMany(filter, session: session).transform(to: [])
        }
    }

    private func custom(_ command: BSONDocument, _ database: MongoSwift.MongoDatabase, _ session: ClientSession?, on eventLoop: EventLoop) -> EventLoopFuture<[DatabaseOutput]> {
        return database.runCommand(command, session: session).map { [$0.databaseOutput(fields: self.query.fields, using: self.decoder)] }
    }
}

extension MongoQueryConverter {

    func index(_ action: DatabaseQuery.Action.MongoIndex, _ database: MongoSwift.MongoDatabase, _ session: ClientSession?, on eventLoop: EventLoop) -> EventLoopFuture<[DatabaseOutput]> {

        let collection = database.collection(self.query.schema)

        switch action {
        case .create(let index):
            return collection.createIndex(index).transform(to: [])
        case .delete(let index):
            return collection.dropIndex(index).transform(to: [])
        }
    }
}

extension MongoQueryConverter {

    private func aggregationPipeline() throws -> [BSONDocument] {

        let schema = self.query.schema
        var pipeline = [BSONDocument]()

        pipeline += try self.query.joins.mongoLookup()
        pipeline += try self.query.filters.mongoMatch(mainSchema: schema, encoder: self.encoder)
        pipeline += try self.query.fields.mongoProject(mainSchema: schema)
        if self.query.isUnique {
            pipeline += try self.query.fields.mongoDistinct(mainSchema: schema)
        }
        pipeline += try self.query.sorts.mongoSort(mainSchema: schema)
        pipeline += try self.query.offsets.mongoSkip()
        pipeline += try self.query.limits.mongoLimit()
        if case .aggregate(let aggregate) = self.query.action {
            pipeline += try aggregate.mongoAggregate(mainSchema: schema)
        }

        return pipeline
    }

    private func filter(_ database: MongoSwift.MongoDatabase, _ session: ClientSession?, on eventLoop: EventLoop) -> EventLoopFuture<BSONDocument> {

        guard !self.query.filters.isEmpty else {
            return eventLoop.makeSucceededFuture(.init())
        }

        do {
            var pipeline = try self.aggregationPipeline()
            pipeline = pipeline.map { stage in
                guard stage.hasKey("$project"), var document = stage["$project"]?.documentValue else {
                    return stage
                }
                document["_id"] = .bool(true)

                return ["$project": .document(document)]
            }
            pipeline.append(["$project": ["_id": true]])

            return database.collection(self.query.schema).aggregate(pipeline, session: session).flatMap { cursor in
                cursor.toArray().map {
                    ["_id": ["$in": .array($0.compactMap { $0["_id"] })]]
                }
            }
        } catch {
            return eventLoop.makeFailedFuture(error)
        }
    }
}

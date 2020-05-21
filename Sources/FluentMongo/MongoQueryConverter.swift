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

    public func convert(_ database: MongoSwift.MongoDatabase, on eventLoop: EventLoop) -> EventLoopFuture<[DatabaseOutput]> {

        let future: EventLoopFuture<[DatabaseOutput]>

        switch self.query.action {
        case .read:
            future = self.find(database, on: eventLoop)
        case .create:
            future = self.insert(database, on: eventLoop)
        case .update:
            future = self.update(database, on: eventLoop)
        case .delete:
            future = self.delete(database, on: eventLoop)
        case .aggregate(let value):
            future = self.aggregate(value, database, on: eventLoop)
        case .custom(let command as Document):
            future = self.custom(command, database, on: eventLoop)
        case .custom:
            future = eventLoop.makeFailedFuture(Error.unsupportedQueryAction)
        }

        return future
    }
}

extension MongoQueryConverter {

    private func find(_ database: MongoSwift.MongoDatabase, on eventLoop: EventLoop) -> EventLoopFuture<[DatabaseOutput]> {

        let collection = database.collection(self.query.schema)

        do {
            let pipeline = try self.aggregationPipeline()

            return collection.aggregate(pipeline, options: nil).flatMap { cursor in
                cursor.toArray().mapEach { $0.databaseOutput(using: self.decoder) }
            }
        } catch {
            return eventLoop.makeFailedFuture(error)
        }

//        TODO: Check this
//        // Running `count` in an aggregation pipeline produce a `nil` document when the provided filter does not match any. Therefore we have to manually set the count to `0`.
//        if let aggregate = query.keys.computed.first?.aggregate, callbacks.count == 0 {
//            var callback: EventLoopFuture<Void>?
//            switch aggregate {
//            case .count:
//                callback = self.eventLoop.submit {
//                    try handler([FluentMongoQuery.defaultAggregateField: 0])
//                }
//            case .group:
//                callback = self.eventLoop.submit {
//                    try handler([FluentMongoQuery.defaultAggregateField: .null])
//                }
//            }
//            callback.map { callbacks.append($0) }
//        }
    }

    private func insert(_ database: MongoSwift.MongoDatabase, on eventLoop: EventLoop) -> EventLoopFuture<[DatabaseOutput]> {
        do {
            let documents = try self.query.input.compactMap { try $0.mongoValue(encoder: self.encoder).documentValue }
            let collection = database.collection(self.query.schema)

            return collection.insertMany(documents).flatMapThrowing { result in
                guard let result = result else {
                    throw Error.invalidResult
                }

                guard documents.count == result.insertedCount else {
                    throw Error.insertManyMismatch(documents.count, result.insertedCount)
                }

                return result.insertedIds.map {
                    Document(dictionaryLiteral: (FieldKey.id.mongoKey, $0.value)).databaseOutput(using: self.decoder)
                }
            }
        } catch {
            return eventLoop.makeFailedFuture(error)
        }
    }

    private func update(_ database: MongoSwift.MongoDatabase, on eventLoop: EventLoop) -> EventLoopFuture<[DatabaseOutput]> {

//        switch (query.data, query.partialData != nil || query.partialCustomData != nil) {
//        case (.none, true):
//            var document = query.partialCustomData ?? Document()
//            document["$set"] = query.partialData.map { .document($0) }
//            if let result = try collection.updateMany(filter: self.filter(query, collection), update: document) {
//                self.logger?.record(query: String(describing: result))
//            }
//        case (.some(let data), false):
//            if let result = try collection.replaceOne(filter: self.filter(query, collection), replacement: data) {
//                self.logger?.record(query: String(describing: result))
//            }
//        default:
//            throw Error.invalidQuery(query)
//        }

        do {
            let documents = try self.query.input.compactMap { try $0.mongoValue(encoder: self.encoder).documentValue }

            return self.filter(database, on: eventLoop).flatMap { filter in
                let collection = database.collection(self.query.schema)
                let updates = documents.map { document in
                    collection.updateMany(filter: filter, update: ["$set": .document(document)])
                }.flatten(on: eventLoop)

                return updates.transform(to: [])
            }
        } catch {
            return eventLoop.makeFailedFuture(error)
        }
    }

    private func delete(_ database: MongoSwift.MongoDatabase, on eventLoop: EventLoop) -> EventLoopFuture<[DatabaseOutput]> {
        return self.filter(database, on: eventLoop).flatMap { filter in
            database.collection(self.query.schema).deleteMany(filter).transform(to: [])
        }
    }

    private func aggregate(_ aggregate: DatabaseQuery.Aggregate, _ database: MongoSwift.MongoDatabase, on eventLoop: EventLoop) -> EventLoopFuture<[DatabaseOutput]> {
        #warning("TODO: implement this")
        return eventLoop.makeSucceededFuture([])
    }

    private func custom(_ command: Document, _ database: MongoSwift.MongoDatabase, on eventLoop: EventLoop) -> EventLoopFuture<[DatabaseOutput]> {
        return database.runCommand(command).map { [$0.databaseOutput(using: self.decoder)] }
    }
}

extension MongoQueryConverter {

/*
    private func sort() -> Document? {
        #warning("TODO: implement this")
        return nil
    }

    private func skip() -> Document? {
        #warning("TODO: implement this")
        return nil
    }

    private func limit() -> Document? {
        #warning("TODO: implement this")
        return nil
    }

    private func aggregates() -> [Document]? {
        #warning("TODO: implement this")
        return nil
    }
*/
}

extension MongoQueryConverter {

    private func aggregationPipeline() throws -> [Document] {

        let schema = self.query.schema
        var pipeline = [Document]()

        pipeline += try self.query.joins.mongoLookup()
        pipeline += try self.query.filters.mongoMatch(mainSchema: schema, encoder: self.encoder)
        pipeline += try self.query.fields.mongoProject(mainSchema: schema)
        if self.query.isUnique {
            pipeline += try self.query.fields.mongoDistinct(mainSchema: schema)
        }
        pipeline += try self.query.sorts.mongoSort(mainSchema: schema)
        pipeline += try self.query.offsets.mongoSkip()
        pipeline += try self.query.limits.mongoLimit()
        // TODO: re-enable all the stages
        //appendStages(self.aggregates())

        return pipeline
    }

    private func filter(_ database: MongoSwift.MongoDatabase, on eventLoop: EventLoop) -> EventLoopFuture<Document> {

        guard !self.query.filters.isEmpty else {
            return eventLoop.makeSucceededFuture(.init())
        }

        do {
            var pipeline = try self.aggregationPipeline()
            pipeline.append(["$project": ["_id": true]])

            return database.collection(self.query.schema).aggregate(pipeline).flatMap { cursor in
                cursor.toArray().map {
                    ["_id": ["$in": .array($0.compactMap { $0["_id"] })]]
                }
            }
        } catch {
            return eventLoop.makeFailedFuture(error)
        }
    }
}


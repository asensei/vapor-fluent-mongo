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
        case .aggregate(_):
            fatalError()
        case .custom(let any):
            fatalError()
            //future custom(any)
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

        return eventLoop.makeSucceededFuture([])
    }

    private func delete(_ database: MongoSwift.MongoDatabase, on eventLoop: EventLoop) -> EventLoopFuture<[DatabaseOutput]> {
        return self.filter(database, on: eventLoop).flatMap { filter in
            database.collection(self.query.schema).deleteMany(filter).transform(to: [])
        }
    }

    private func custom(_ database: MongoSwift.MongoDatabase, on eventLoop: EventLoop) -> EventLoopFuture<[DatabaseOutput]> {
        #warning("TODO: implement this")
        return eventLoop.makeSucceededFuture([])
    }
}

extension MongoQueryConverter {
/*
    private func joins() throws -> [Document] {
        return try self.query.joins.map { join in
            switch join {
            case .join(let schema, let foreign, let local, let method):
                let collection = try schema.schema().name
                let lookup: Document = [
                    "$lookup": [
                        "from": collection,
                        "localField": try local.field().path.joined(separator: "."),
                        "foreignField": try foreign.field().path.joined(separator: "."),
                        "as": collection
                    ] as Document
                ]

                let unwind: Document = [
                    "$unwind": [
                        "path": "$" + collection,
                        "preserveNullAndEmptyArrays": method.isOuter
                    ] as Document
                ]

                return [lookup, unwind]

            case .custom(let value):
                fatalError()
            }
        }
    }
*/

    private func match(aggregate: Bool) throws -> Document? {

        guard !self.query.filters.isEmpty else {
            return nil
        }

        let filter = try self.query.filters.reduce(into: Document()) { document, filter in

            // Build
            switch filter {
            case .value(let field, let method, let value):
//                #warning("TODO: check if we need path or pathWithNamespace - related to byRemovingKeysPrefix")
                let key = try field.mongoKeyPath(namespace: aggregate)
                let mongoOperator = try method.mongoOperator()
                let bsonValue = try value.mongoValue(encoder: self.encoder)
                document[key] = [mongoOperator: bsonValue]
            case .field(let lhs, let method, let rhs):
                fatalError()
            case .group(let filters, let relation):
                fatalError()
            case .custom(let document as Document):
                fatalError()
            default:
                break
            }
        }

        //        // Apply
        //
        //        let filterByRemovingRootNamespace = filter.byRemovingKeysPrefix(query.schema)
        //
        //        switch query.filters {
        //        case .some(let document):
        //            query.filter = [query.defaultFilterRelation.rawValue: [document, filterByRemovingRootNamespace]]
        //        case .none:
        //            return filterByRemovingRootNamespace
        //        }

        return filter
    }

    private func projection() -> Document? {
        var projection = Document()

        for field in self.query.fields {

            let key: String

            switch field {
            case .path(let value, let schema):
                let path = self.query.schema == schema
                    ? value
                    : ([.string(schema)] + value)
                key = path.mongoKeys.dotNotation
            case .custom(let value as String):
                key = value
            default:
                continue
            }

            projection[key] = true
        }

        guard !projection.isEmpty else {
            return nil
        }

        projection["_id"] = true

        return projection
    }
/*
    private func distinct() -> [Document]? {
        #warning("TODO: Not supported")
        guard /*self.query.isDistinct*/ false else {
            return nil
        }

        var stages = [Document]()
        var group = Document()
        var id = Document()

        for field in self.query.fields {

            let key: String
            let value: String

            switch field {
            case .field(let path, let schema, let alias):
                // It is not possible to use dots when specifying an id field for $group
                let queryField = DatabaseQuery.Field.QueryField(path: path, schema: schema, alias: alias)
                key = queryField.pathWithNamespace.joined(separator: ":")
                value = "$" + (self.query.schema == schema
                    ? path
                    : queryField.pathWithNamespace
                ).joined(separator: ".")
            case .custom(let value as String):
                #warning("TODO: Not supported")
                fatalError()
            default:
                continue
            }

            id[key] = value
        }

        if id.isEmpty {
            id[self.query.schema + ":_id"] = "$_id"
        }

        group["_id"] = id
        group["doc"] = ["$first": "$$ROOT"] as Document

        stages.append(["$group": group])
        stages.append(["$replaceRoot": ["newRoot": "$doc"] as Document])

        return stages
    }*/
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
        var pipeline = [Document]()

        func appendStage(_ name: String, _ value: Document?) {
            guard let value = value else {
                return
            }

            pipeline.append([name: .document(value)])
        }

        func appendStages(_ values: [Document]?) {
            guard let values = values, !values.isEmpty else {
                return
            }

            pipeline.append(contentsOf: values)
        }

        // TODO: re-enable all the stages
        //let joins = try self.joins()
        //appendStages(joins)
        appendStage("$match", try self.match(aggregate: false))
        appendStage("$project", self.projection())
        //appendStages(self.distinct())
        //appendStage("$sort", self.sort())
        //appendStage("$skip", self.skip())
        //appendStage("$limit", self.limit())
        //appendStages(self.aggregates())

        // Remove joined collections from the output
/*
        if !joins.isEmpty {
            var projection = Document()
            for join in joins {
                guard let field = join["$lookup", "as"] as? String else {
                    continue
                }
                projection[field] = false
            }
            appendStage("$project", projection)
        }
*/
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


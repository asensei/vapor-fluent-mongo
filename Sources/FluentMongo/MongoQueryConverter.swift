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

    public init(_ query: DatabaseQuery, using encoder: BSONEncoder) {
        self.query = query
        self.encoder = encoder
    }

    private let query: DatabaseQuery
    
    private let encoder: BSONEncoder

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
        #warning("TODO: implement this")
        return eventLoop.makeSucceededFuture([])
    }

    private func insert(_ database: MongoSwift.MongoDatabase, on eventLoop: EventLoop) -> EventLoopFuture<[DatabaseOutput]> {

//        var documents = [Document]()
//
//        let fields = try self.query.fields.map { try $0.field().path }
//
//        for input in self.query.input {
//            var document = Document()
//            for (field, value) in zip(fields, input) where !field.starts(with: ["id"]) {
//                #warning("TODO: rename id to _id")
//                document[field] = try self.bsonValue(value)
//            }
//            documents.append(document)
//        }
//
//        func defaultRow() -> [DatabaseRow] {
//            // tanner: you should always return a row on create containing all the default values - if there are no default or db generated values, then just return an empty one
//            return documents.count == 1 ? [Document()] : []
//        }
//
//        let collection = database.collection(self.query.schema)
//
//        switch documents.count {
//        case 1:
//            guard let result = try collection.insertOne(documents.removeFirst()) else {
//                return defaultRow()
//            }
//            // TODO: Log result
//            #warning("TODO: Handle this correctly")
//            return [["fluentID": 0] as Document]
//        default:
//            let result = try collection.insertMany(documents)
//            // TODO: Log result
//            return defaultRow()
//        }
        #warning("TODO: implement this")
        return eventLoop.makeSucceededFuture([])
    }

    private func update(_ database: MongoSwift.MongoDatabase, on eventLoop: EventLoop) -> EventLoopFuture<[DatabaseOutput]> {
        #warning("TODO: implement this")
        return eventLoop.makeSucceededFuture([])
    }

    private func delete(_ database: MongoSwift.MongoDatabase, on eventLoop: EventLoop) -> EventLoopFuture<[DatabaseOutput]> {
        let collection = database.collection(self.query.schema)
//        let filter = try self.filter(database)
//        if let result = try collection.deleteMany(filter) {
//            #warning("TODO: Log")
//        }

        return eventLoop.makeSucceededFuture([])
    }

    private func custom(_ database: MongoSwift.MongoDatabase, on eventLoop: EventLoop) -> EventLoopFuture<[DatabaseOutput]> {
        #warning("TODO: implement this")
        return eventLoop.makeSucceededFuture([])
    }
}
/*
extension MongoQueryConverter {

    private func bsonValue(_ value: DatabaseQuery.Value) throws -> BSONValue {
        switch value {
        case .bind(let encodable):
            return try self.encoder.encode(encodable)
        case .null:
            return BSONNull()
        case .array(let values):
            return try values.map { try self.bsonValue($0) }
        case .default:
            return BSONNull() // ignore if not _id
        case .custom(let value as BSONValue):
            return value
        case .custom:
            fatalError() // not supported
        case .dictionary(let dict):
            fatalError() // never used
        }
    }

    private func `operator`(from method: DatabaseQuery.Filter.Method) -> String {
        switch method {
        case .equality(let inverse):
            return inverse ? "$ne" : "$eq"
        case .order(let inverse, let equality):
            switch (inverse, equality) {
            case (true, true):
                return "$lte"
            case (true, false):
                return "$lt"
            case (false, true):
                return "$gte"
            case (false, false):
                return "$gt"
            }
        case .subset(let inverse):
            return inverse ? "$nin" : "$in"
        case .contains(let inverse, let location):
            #warning("TODO: implement this")
            fatalError()
        case .custom(let value as String):
            return value
        default:
            #warning("TODO: implement this")
            fatalError() // not supported
        }
    }
}

extension MongoQueryConverter {

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

    private func match() throws -> Document? {

        guard !self.query.filters.isEmpty else {
            return nil
        }

        return try self.query.filters.reduce(into: Document()) { document, filter in

            // Build
            switch filter {
            case .value(let field, let method, let value):
                #warning("TODO: check if we need path or pathWithNamespace - related to byRemovingKeysPrefix")
                let pathWithNamespace = try field.field()/*pathWithNamespace*/.path.joined(separator: ".")
                let op = self.operator(from: method)
                let value = try self.bsonValue(value)
                document[pathWithNamespace] = [op: value] as Document
            case .field(let lhs, let method, let rhs):
                fatalError()
            case .group(let filters, let relation):
                fatalError()
            case .custom(let document as Document):
                fatalError()
            default:
                break
            }

            // Apply
            /*
            let filterByRemovingRootNamespace = filter.byRemovingKeysPrefix(query.collection)

            switch query.filter {
            case .some(let document):
                query.filter = [query.defaultFilterRelation.rawValue: [document, filterByRemovingRootNamespace]]
            case .none:
                query.filter = filterByRemovingRootNamespace
            }
             */
        }
    }

    private func projection() -> Document? {
        var projection = Document()

        for field in self.query.fields {

            let key: String

            switch field {
            case .field(let path, let schema, let alias):
                let path = self.query.schema == schema
                    ? path
                    : DatabaseQuery.Field.QueryField(path: path, schema: schema, alias: alias).pathWithNamespace
                key = path.joined(separator: ".")
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
    }

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
}

extension MongoQueryConverter {

    private func aggregationPipeline() throws -> [Document] {
        var pipeline = [Document]()

        func appendStage(_ name: String, _ value: Document?) {
            guard let value = value else {
                return
            }

            pipeline.append([name: value])
        }

        func appendStages(_ values: [Document]?) {
            guard let values = values, !values.isEmpty else {
                return
            }

            pipeline.append(contentsOf: values)
        }

        let joins = try self.joins()
        appendStages(joins)
        appendStage("$match", try self.match())
        appendStage("$project", self.projection())
        appendStages(self.distinct())
        appendStage("$sort", self.sort())
        appendStage("$skip", self.skip())
        appendStage("$limit", self.limit())
        appendStages(self.aggregates())

        // Remove joined collections from the output
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

        return pipeline
    }

    private func filter(_ database: MongoDatabase) throws -> Document {

        guard !self.query.filters.isEmpty else {
            return [:]
        }

        var pipeline = try self.aggregationPipeline()
        pipeline.append(["$project": ["_id": true] as Document])

        let cursor = try database.collection(self.query.schema).aggregate(pipeline)
        let identifiers = cursor.compactMap { $0["_id"] }

        return ["_id": ["$in": identifiers] as Document]
    }
}
*/

//
//  MongoConnection.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 30/11/2018.
//  Copyright © 2018 Asensei Inc. All rights reserved.
//

import Foundation
import MongoSwift
import Fluent

/// A Mongo frontend client.
public final class MongoConnection: BasicWorker, DatabaseConnection {

    public required init(config: MongoDatabaseConfig, on worker: Worker) throws {
        self.config = config
        self.worker = worker
        self.client = try MongoClient(connectionString: config.connectionURL.absoluteString, options: config.options)
        self.isClosed = false
        self.logger = nil
    }

    private let config: MongoDatabaseConfig

    private let worker: Worker

    private let client: MongoClient

    /// See `Worker`.
    public var eventLoop: EventLoop {
        return self.worker.eventLoop
    }

    /// If non-nil, will log queries.
    public var logger: DatabaseLogger?

    /// See `Extendable`.
    public var extend: Extend = [:]

    /// See `DatabaseConnection`.
    public typealias Database = MongoDatabase

    public private(set)var isClosed: Bool

    /// Closes the `DatabaseConnection`.
    public func close() {
        self.client.close()
        self.isClosed = true
    }

    /// See `DatabaseQueryable`.

    public func query(_ query: Database.Query, _ handler: @escaping (Database.Output) throws -> Void) -> Future<Void> {
        do {
            self.logger?.record(query: String(describing: query))
            let database = try self.client.db(config.database)
            let collection = try database.collection(query.collection)

            switch query.action {
            case .insert:
                guard let document = query.data else {
                    throw Error.invalidQuery(query)
                }
                if let result = try collection.insertOne(document) {
                    self.logger?.record(query: String(describing: result))
                }
            case .find:
                let cursor = try collection.aggregate(query.aggregationPipeline())
                var count = 0
                try cursor.forEach {
                    count += 1
                    try handler($0)
                }
                // Running `count` in an aggregation pipeline produce a `nil` document when the provided filter does not match any. Therefore we have to manually set the count to `0`.
                if let aggregate = query.keys.computed.first?.aggregate, count == 0 {
                    switch aggregate {
                    case .count:
                        try handler([FluentMongoQuery.defaultAggregateField: 0])
                    case .group:
                        try handler([FluentMongoQuery.defaultAggregateField: BSONNull()])
                    }
                }
            case .update:
                switch (query.data, query.partialData) {
                case (.none, .some(let document)):
                    if let result = try collection.updateMany(filter: self.filter(query, collection), update: ["$set": document]) {
                        self.logger?.record(query: String(describing: result))
                    }
                case (.some(let document), .none):
                    if let result = try collection.replaceOne(filter: self.filter(query, collection), replacement: document) {
                        self.logger?.record(query: String(describing: result))
                    }
                default:
                    throw Error.invalidQuery(query)
                }
            case .delete:
                if let result = try collection.deleteMany(self.filter(query, collection)) {
                    self.logger?.record(query: String(describing: result))
                }
            }

            return self.worker.future()
        } catch {
            return self.worker.future(error: error)
        }
    }

    private func filter(_ query: Database.Query, _ collection: MongoCollection<Document>) throws -> FluentMongoQueryFilter {

        guard let filter = query.filter, !filter.isEmpty else {
            return [:]
        }

        var pipeline = query.aggregationPipeline()
        pipeline.append(["$project": ["_id": true] as Document])
        let cursor = try collection.aggregate(pipeline)
        let identifiers = cursor.compactMap { $0["_id"] }

        return ["_id": ["$in": identifiers] as Document]
    }
}

public extension MongoConnection {
    public enum Error: Swift.Error {
        case invalidQuery(Database.Query)
    }
}

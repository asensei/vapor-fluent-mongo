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
public final class MongoConnection: BasicWorker, DatabaseConnection, DatabaseQueryable {

    public required init(config: MongoDatabaseConfig, on worker: Worker) throws {
        self.config = config
        self.worker = worker
        self.client = try MongoClient(connectionString: config.connectionURL.absoluteString, options: config.options)
        self.isClosed = false
        self.logger = nil
    }

    private let config: MongoDatabaseConfig

    private let worker: Worker

    let client: MongoClient

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
        } catch let error as MongoError {
            switch error {
            // TODO: update this as soon as https://github.com/mongodb/mongo-swift-driver/issues/200 is fixed.
            case .commandError(let message) where message.hasPrefix("E11000"):
                return self.worker.future(error: Error.duplicatedKey(message))
            default:
                return self.worker.future(error: Error.underlyingDriverError(error))
            }
        } catch {
            return self.worker.future(error: Error.underlyingDriverError(error))
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

// MARK: - Internal Indexing Helpers

extension MongoConnection {

    func createIndex(_ index: IndexModel, in collection: String) -> Future<Void> {
        do {
            guard !index.keys.isEmpty else {
                throw IndexBuilderError.invalidKeys
            }
            self.logger?.record(query: "MongoConnection.createIndex")
            let database = try self.client.db(config.database)
            self.logger?.record(query: "Create index on \(collection)")
            _ = try database.collection(collection).createIndex(index)

            return self.worker.future()
        } catch {
            return self.worker.future(error: error)
        }
    }

    func dropIndex(_ index: IndexModel, in collection: String) -> Future<Void> {
        do {
            guard !index.keys.isEmpty else {
                throw IndexBuilderError.invalidKeys
            }

            self.logger?.record(query: "MongoConnection.dropIndex")
            let database = try self.client.db(config.database)
            self.logger?.record(query: "Drop index on \(collection)")
            _ = try database.collection(collection).dropIndex(index)

            return self.worker.future()
        } catch {
            return self.worker.future(error: error)
        }
    }
}

// MARK: - Internal MigrationSupporting Helpers

extension MongoConnection {

    func prepareMigrationMetadata() -> Future<Void> {
        do {
            self.logger?.record(query: "MongoConnection.prepareMigrationMetadata")
            let database = try self.client.db(config.database)
            let collection = MigrationLog<MongoDatabase>.entity
            self.logger?.record(query: "Create collection: \(collection)")
            _ = try database.createCollection(collection)

            return self.worker.future()
        } catch {
            return self.worker.future(error: error)
        }
    }

    func revertMigrationMetadata() -> Future<Void> {
        do {
            self.logger?.record(query: "MongoConnection.revertMigrationMetadata")
            let database = try self.client.db(config.database)
            let collection = MigrationLog<MongoDatabase>.entity
            self.logger?.record(query: "Drop collection: \(collection)")
            _ = try database.collection(collection).drop()

            return self.worker.future()
        } catch {
            return self.worker.future(error: error)
        }
    }
}

public extension MongoConnection {
    public enum Error: Swift.Error {
        case invalidQuery(Database.Query)
        case duplicatedKey(String)
        case underlyingDriverError(Swift.Error)

        var localizedDescription: String {
            switch self {
            case .invalidQuery(let query):
                return "Invalid query. \(String(describing: query))"
            case .duplicatedKey(let message):
                return "Duplicated key. \(message)"
            case .underlyingDriverError(let error):
                return error.localizedDescription
            }
        }
    }
}

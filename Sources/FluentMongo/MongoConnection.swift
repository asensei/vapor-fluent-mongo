//
//  MongoConnection.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 30/11/2018.
//  Copyright © 2018 Asensei Inc. All rights reserved.
//

import Foundation
import NIO
import MongoSwift
import Fluent

/// A Mongo frontend client.
public final class MongoConnection: BasicWorker, DatabaseConnection, DatabaseQueryable {

    public required init(
        client: MongoClient,
        database: String,
        threadPool: BlockingIOThreadPool,
        logger: DatabaseLogger? = nil,
        on eventLoop: EventLoop
    ) {
        self.client = client
        self.database = database
        self.threadPool = threadPool
        self.eventLoop = eventLoop
        self.isClosed = false
        self.logger = logger
    }

    public let database: String

    public let eventLoop: EventLoop

    private let client: MongoClient

    private let threadPool: BlockingIOThreadPool

    /// If non-nil, will log queries.
    public var logger: DatabaseLogger?

    /// See `Extendable`.
    public var extend: Extend = [:]

    /// See `DatabaseConnection`.
    public typealias Database = MongoDatabase

    public private(set)var isClosed: Bool

    /// Closes the `DatabaseConnection`.
    public func close() {
        self.isClosed = true
    }

    /// See `DatabaseQueryable`.

    public func query(_ query: Database.Query, _ handler: @escaping (Database.Output) throws -> Void) -> Future<Void> {

        let promise = self.eventLoop.newPromise(of: Void.self)
        self.threadPool.submit { _ in

            var callbacks: [EventLoopFuture<Void>] = []
            self.logger?.record(query: String(describing: query))
            let database = self.client.db(self.database)
            let collection = database.collection(query.collection)

            do {
                switch query.action {
                case .insert:
                    guard let document = query.data else {
                        throw Error.invalidQuery(query)
                    }
                    if let result = try collection.insertOne(document) {
                        self.logger?.record(query: String(describing: result))
                    }
                case .find:
                    let cursor = try collection.aggregate(query.aggregationPipeline(), options: query.aggregateOptions)
                    cursor.forEach { document in
                        let callback = self.eventLoop.submit {
                            try handler(document)
                        }
                        callbacks.append(callback)
                    }
                    // Running `count` in an aggregation pipeline produce a `nil` document when the provided filter does not match any. Therefore we have to manually set the count to `0`.
                    if let aggregate = query.keys.computed.first?.aggregate, callbacks.count == 0 {
                        var callback: EventLoopFuture<Void>?
                        switch aggregate {
                        case .count:
                            callback = self.eventLoop.submit {
                                try handler([FluentMongoQuery.defaultAggregateField: 0])
                            }
                        case .group:
                            callback = self.eventLoop.submit {
                                try handler([FluentMongoQuery.defaultAggregateField: .null])
                            }
                        }
                        callback.map { callbacks.append($0) }
                    }
                case .update:
                    switch (query.data, query.partialData != nil || query.partialCustomData != nil) {
                    case (.none, true):
                        var document = query.partialCustomData ?? Document()
                        document["$set"] = query.partialData.map { .document($0) }
                        if let result = try collection.updateMany(filter: self.filter(query, collection), update: document) {
                            self.logger?.record(query: String(describing: result))
                        }
                    case (.some(let data), false):
                        if let result = try collection.replaceOne(filter: self.filter(query, collection), replacement: data) {
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

                if callbacks.isEmpty {
                    promise.succeed()
                } else {
                    EventLoopFuture<Void>.andAll(callbacks, eventLoop: self.eventLoop).cascade(promise: promise)
                }
            } catch let error as ServerError {
                switch error {
                case .writeError(let writeError, let writeConcernError, _) where writeError?.code == 11000 || writeConcernError?.code == 11000:
                    return promise.fail(error: Error.duplicatedKey(error.errorDescription ?? "No error description available."))
                default:
                    return promise.fail(error: Error.underlyingDriverError(error))
                }
            } catch {
                return promise.fail(error: Error.underlyingDriverError(error))
            }
        }

        return promise.futureResult
    }

    private func filter(_ query: Database.Query, _ collection: MongoCollection<Document>) throws -> FluentMongoQueryFilter {

        guard let filter = query.filter, !filter.isEmpty else {
            return [:]
        }

        var pipeline = query.aggregationPipeline()
        pipeline.append(["$project": ["_id": true]])
        let cursor = try collection.aggregate(pipeline)
        let identifiers = cursor.compactMap { $0["_id"] }

        return ["_id": ["$in": .array(identifiers)]]
    }

    deinit {
        self.close()
    }
}

// MARK: - Internal Indexing Helpers

extension MongoConnection {

    func createIndex(_ index: IndexModel, in collection: String) -> Future<Void> {

        let promise = self.eventLoop.newPromise(of: Void.self)

        self.threadPool.submit { _ in
            do {
                guard !index.keys.isEmpty else {
                    throw IndexBuilderError.invalidKeys
                }

                self.logger?.record(query: "MongoConnection.createIndex")
                let database = self.client.db(self.database)
                self.logger?.record(query: "Create index on \(collection)")
                _ = try database.collection(collection).createIndex(index)

                return promise.succeed()
            } catch {
                return promise.fail(error: error)
            }
        }

        return promise.futureResult
    }

    func dropIndex(_ index: IndexModel, in collection: String) -> Future<Void> {

        let promise = self.eventLoop.newPromise(of: Void.self)

        self.threadPool.submit { _ in
            do {
                guard !index.keys.isEmpty else {
                    throw IndexBuilderError.invalidKeys
                }

                self.logger?.record(query: "MongoConnection.dropIndex")
                let database = self.client.db(self.database)
                self.logger?.record(query: "Drop index on \(collection)")
                _ = try database.collection(collection).dropIndex(index)

                return promise.succeed()
            } catch {
                return promise.fail(error: error)
            }
        }

        return promise.futureResult
    }
}

// MARK: - Internal MigrationSupporting Helpers

extension MongoConnection {

    func prepareMigrationMetadata() -> Future<Void> {

        let promise = self.eventLoop.newPromise(of: Void.self)

        self.threadPool.submit { _ in
            do {
                self.logger?.record(query: "MongoConnection.prepareMigrationMetadata")
                let database = self.client.db(self.database)
                let collection = MigrationLog<MongoDatabase>.entity
                let collections = try database.listCollections(["name": .string(collection)])
                if collections.contains(where: { $0.name == collection }) {
                    self.logger?.record(query: "Collection \"\(collection)\" already exists. Skipping creation.")
                } else {
                    self.logger?.record(query: "Create collection: \(collection)")
                    _ = try database.createCollection(collection)
                }

                return promise.succeed()
            } catch {
                return promise.fail(error: error)
            }
        }

        return promise.futureResult
    }

    func revertMigrationMetadata() -> Future<Void> {

        let promise = self.eventLoop.newPromise(of: Void.self)

        self.threadPool.submit { _ in
            do {
                self.logger?.record(query: "MongoConnection.revertMigrationMetadata")
                let database = self.client.db(self.database)
                let collection = MigrationLog<MongoDatabase>.entity
                self.logger?.record(query: "Drop collection: \(collection)")
                _ = try database.collection(collection).drop()

                return promise.succeed()
            } catch {
                return promise.fail(error: error)
            }
        }

        return promise.futureResult
    }
}

extension MongoConnection {
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

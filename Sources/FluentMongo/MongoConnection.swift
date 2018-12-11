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

    public func query(_ query: Database.Query, _ handler: @escaping (Database.Output) throws -> ()) -> Future<Void> {
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
                try collection
                    .find(query.filter ?? [:], options: FindOptions(limit: query.limit, skip: query.skip))
                    .forEach { try handler($0) }
            case .update:
                guard let document = query.data else {
                    throw Error.invalidQuery(query)
                }
                if let result = try collection.updateMany(filter: query.filter ?? [:], update: document) {
                    self.logger?.record(query: String(describing: result))
                }
            case .delete:
                if let result = try collection.deleteMany(query.filter ?? [:]) {
                    self.logger?.record(query: String(describing: result))
                }
            }

            return self.worker.future()
        } catch {
            return self.worker.future(error: error)
        }
    }
}

public extension MongoConnection {
    public enum Error: Swift.Error {
        case invalidQuery(Database.Query)
    }
}

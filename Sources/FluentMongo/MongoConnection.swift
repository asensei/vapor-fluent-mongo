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
public final class MongoConnection: BasicWorker, DatabaseConnection/*, DatabaseQueryable*/ {

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

    public func query(_ query: FluentMongoQuery, _ handler: @escaping (Document) throws -> ()) -> Future<Void> {
        do {
            let database = try self.client.db(config.database)
            let collection = try database.collection(query.collection)

            switch query.action {
            case .insert:
                guard let document = query.data else {
                    break
                }
                try collection.insertOne(document)
            case .find:
                try collection
                    .find(query.filter ?? [:], options: nil)
                    .forEach { try handler($0) }
            case .update:
                break
            case .delete:
                break
            }

            return self.worker.future()
        } catch {
            return self.worker.future(error: error)
        }
    }
}

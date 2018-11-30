//
//  MongoDatabase.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 30/11/2018.
//  Copyright © 2018 Asensei Inc. All rights reserved.
//

import Foundation
import Fluent

/// Creates connections to an identified Mongo database.
public final class MongoDatabase: Database {
    /// This database's configuration.
    public let config: MongoDatabaseConfig

    /// Creates a new `MongoDatabase`.
    public init(config: MongoDatabaseConfig) {
        self.config = config
    }

    /// See `Database`
    public func newConnection(on worker: Worker) -> Future<MongoConnection> {
        return MongoConnection.connect(config: self.config, on: worker)
    }
}

extension DatabaseIdentifier {
    /// Default identifier for `MongoDatabase`.
    public static var mongo: DatabaseIdentifier<MongoDatabase> {
        return .init("mongo")
    }
}

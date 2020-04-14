//
//  MongoDatabase.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 30/11/2018.
//  Copyright © 2018 Asensei Inc. All rights reserved.
//

import Foundation
import Fluent
import MongoSwift

/// Creates connections to an identified Mongo database.
public final class MongoDatabase: Database {
    /// This database's configuration.
    public let config: MongoDatabaseConfig

    private let threadPool: BlockingIOThreadPool

    /// Creates a new `MongoDatabase`.
    public init(config: MongoDatabaseConfig, threadPool: BlockingIOThreadPool) {
        self.config = config
        self.threadPool = threadPool
    }

    /// See `Database`
    public func newConnection(on worker: Worker) -> Future<MongoConnection> {
        return MongoConnection.connect(
            config: self.config,
            threadPool: self.threadPool,
            on: worker.eventLoop
        )
    }
}

extension MongoDatabase: BSONCoder {

    public static var encoder: BSONEncoder = {
        return BSONEncoder()
    }()

    public static var decoder: BSONDecoder = {
        return BSONDecoder()
    }()
}

extension DatabaseIdentifier {
    /// Default identifier for `MongoDatabase`.
    public static var mongo: DatabaseIdentifier<MongoDatabase> {
        return .init("mongo")
    }
}

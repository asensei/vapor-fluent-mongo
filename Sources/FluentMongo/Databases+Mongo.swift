//
//  Databases+Mongo.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 21/10/2019.
//  Copyright © 2019 Asensei Inc. All rights reserved.
//

import Foundation
import NIO
import FluentKit
import Logging
import MongoSwift
/*
extension DatabaseID {
    public static var mongo: DatabaseID {
        return .init(string: "mongo")
    }
}

extension Databases {
    public func mongo(
        configuration: MongoConfiguration,
        threadPool: NIOThreadPool,
        poolConfiguration: ConnectionPoolConfiguration = .init(),
        logger: Logger = .init(label: "vapor.fluent.mongo"),
        as id: DatabaseID = .mongo,
        isDefault: Bool = true,
        on eventLoopGroup: EventLoopGroup
    ) {
        let db = MongoConnectionSource(
            configuration: configuration,
            threadPool: threadPool,
            logger: logger
        )
        let pool = ConnectionPool(configuration: poolConfiguration, source: db, on: eventLoopGroup)
        self.add(MongoDatabaseDriver(pool: pool), logger: logger, as: id, isDefault: isDefault)
    }
}

extension DatabaseQuery.Value {
    public static func mongo(_ value: BSONValue) -> DatabaseQuery.Value {
        return .custom(value)
    }
}
*/

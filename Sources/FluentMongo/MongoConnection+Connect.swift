//
//  MongoConnection+Connect.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 30/11/2018.
//  Copyright © 2018 Asensei Inc. All rights reserved.
//

import Foundation
import NIO
import MongoSwift

extension MongoConnection {

    public static func connect(config: MongoDatabaseConfig, threadPool: BlockingIOThreadPool, on eventLoop: EventLoop) -> EventLoopFuture<MongoConnection> {

        let promise = eventLoop.newPromise(of: MongoConnection.self)

        threadPool.submit { _ in
            do {
                let connection = try MongoConnection(
                    client: MongoClient(config.connectionURL.absoluteString, options: config.options),
                    database: config.database,
                    threadPool: threadPool,
                    on: eventLoop
                )
                promise.succeed(result: connection)
            } catch {
                promise.fail(error: error)
            }
        }

        return promise.futureResult
    }
}

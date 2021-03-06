//
//  FluentMongoConfiguration.swift
//  FluentMongo
//
//  Created by Dale Buckley on 13/05/2020.
//  Copyright © 2019 Asensei Inc. All rights reserved.
//

import Foundation
import NIO
import AsyncKit
import FluentKit

struct FluentMongoConfiguration: DatabaseConfiguration {

    let configuration: MongoConfiguration

    let maxConnectionsPerEventLoop: Int

    /// The amount of time to wait for a connection from the connection pool before timing out.
    let connectionPoolTimeout: NIO.TimeAmount

    var middleware: [AnyModelMiddleware]

    func makeDriver(for databases: Databases) -> DatabaseDriver {

        let db = MongoConnectionSource(
            configuration: self.configuration
        )

        let pool = EventLoopGroupConnectionPool(
            source: db,
            maxConnectionsPerEventLoop: self.maxConnectionsPerEventLoop,
            requestTimeout: self.connectionPoolTimeout,
            on: databases.eventLoopGroup
        )

        return MongoDatabaseDriver(pool: pool)
    }
}

extension DatabaseConfigurationFactory {

    public static func mongo(
        scheme: String = "mongodb",
        user: String? = nil,
        password: String? = nil,
        host: String = "127.0.0.1",
        port: Int = 27017,
        database: String,
        options: MongoClientOptions? = nil,
        maxConnectionsPerEventLoop: Int = 1,
        connectionPoolTimeout: NIO.TimeAmount = .seconds(10)
    ) throws -> Self {

        let configuration = try MongoConfiguration(
            scheme: scheme,
            user: user,
            password: password,
            host: host,
            port: port,
            database: database,
            options: options
        )

        return .init {
            FluentMongoConfiguration(
                configuration: configuration,
                maxConnectionsPerEventLoop: maxConnectionsPerEventLoop,
                connectionPoolTimeout: connectionPoolTimeout,
                middleware: []
            )
        }
    }

    public static func mongo(
        connectionString: String,
        options: MongoClientOptions? = nil,
        maxConnectionsPerEventLoop: Int = 1,
        connectionPoolTimeout: NIO.TimeAmount = .seconds(10)
    ) throws -> Self {

        let configuration = try MongoConfiguration(
            connectionString: connectionString,
            options: options
        )

        return .init {
            FluentMongoConfiguration(
                configuration: configuration,
                maxConnectionsPerEventLoop: maxConnectionsPerEventLoop,
                connectionPoolTimeout: connectionPoolTimeout,
                middleware: []
            )
        }
    }

    public static func mongo(
        connectionURL: URL,
        options: MongoClientOptions? = nil,
        maxConnectionsPerEventLoop: Int = 1,
        connectionPoolTimeout: NIO.TimeAmount = .seconds(10)
    ) throws -> Self {

        let configuration = try MongoConfiguration(
            connectionURL: connectionURL,
            options: options
        )

        return .init {
            FluentMongoConfiguration(
                configuration: configuration,
                maxConnectionsPerEventLoop: maxConnectionsPerEventLoop,
                connectionPoolTimeout: connectionPoolTimeout,
                middleware: []
            )
        }
    }

    public static func mongo(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        maxConnectionsPerEventLoop: Int = 1,
        connectionPoolTimeout: NIO.TimeAmount = .seconds(10)
    ) throws -> Self {

        let configuration = try MongoConfiguration(environment: environment)

        return .init {
            FluentMongoConfiguration(
                configuration: configuration,
                maxConnectionsPerEventLoop: maxConnectionsPerEventLoop,
                connectionPoolTimeout: connectionPoolTimeout,
                middleware: []
            )
        }
    }
}

//
//  MongoDatabaseConfig.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 30/11/2018.
//  Copyright © 2018 Asensei Inc. All rights reserved.
//

import Foundation
import MongoSwift

/// Config options for a `MongoDatabase`
public struct MongoDatabaseConfig {

    /// Creates a `MongoDatabaseConfig` with default settings.
    public static func `default`(database: String, options: ClientOptions? = nil) throws -> MongoDatabaseConfig {
        return try .init(database: database, options: options)
    }

    /// Connection string.
    public let connectionURL: URL

    public let database: String

    public let options: ClientOptions?

    /// Creates a new `MongoDatabaseConfig`.
    public init(connectionString: String, options: ClientOptions? = nil) throws {
        guard let url = URL(string: connectionString) else {
            throw URLError(.badURL)
        }

        try self.init(connectionURL: url, options: options)
    }

    public init(connectionURL: URL, options: ClientOptions? = nil) throws {
        guard let database = connectionURL.databaseName else {
            throw URLError(.badURL)
        }

        self.connectionURL = connectionURL
        self.database = database
        self.options = options
    }

    public init(
        scheme: String = "mongodb",
        user: String? = nil,
        password: String? = nil,
        host: String = "127.0.0.1",
        port: Int = 27017,
        database: String,
        options: ClientOptions? = nil
        ) throws {

        var components = URLComponents()
        components.scheme = scheme
        components.user = user
        components.password = password
        components.host = host
        components.port = port
        components.path = "/" + database

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        try self.init(connectionURL: url, options: options)
    }
}
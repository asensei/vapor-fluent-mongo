//
//  MongoConfiguration.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 21/10/2019.
//  Copyright © 2019 Asensei Inc. All rights reserved.
//

import Foundation
import MongoSwift
/*
public struct MongoConfiguration {

    // MARK: Accessing Attributes

    public let connectionURL: URL

    public let database: String

    public let options: ClientOptions?

    // MARK: Initialization

    /// Creates a new `MongoConfiguration`.
    public init(connectionString: String, options: ClientOptions? = nil) throws {
        guard let url = URL(string: connectionString) else {
            throw URLError(.badURL)
        }

        try self.init(connectionURL: url, options: options)
    }

    public init(connectionURL: URL, options: ClientOptions? = nil) throws {
        guard let database = connectionURL.path.split(separator: "/").last.flatMap(String.init) else {
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

    public init(environment: [String: String] = ProcessInfo.processInfo.environment) throws {

        guard let connectionString = environment[EnvironmentKey.connectionURL.rawValue] else {
            throw Error.missingEnvironmentKey(.connectionURL)
        }

        try self.init(connectionString: connectionString)
    }
}

extension MongoConfiguration {

    public enum EnvironmentKey: String {
        case connectionURL = "FLUENT_MONGO_CONNECTION_URL"
    }

    public enum Error: Swift.Error {
        case missingEnvironmentKey(EnvironmentKey)
    }
}
*/
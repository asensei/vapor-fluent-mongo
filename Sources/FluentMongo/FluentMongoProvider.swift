//
//  FluentMongoProvider.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 30/11/2018.
//  Copyright © 2018 Asensei Inc. All rights reserved.
//

import Fluent
import Service
import MongoSwift

public final class FluentMongoProvider: Provider {

    public init() {}

    public func register(_ services: inout Services) throws {
        try services.register(FluentProvider())
        try services.register(DatabaseKitProvider())
        services.register(MongoDatabaseConfig.self)
        services.register(MongoDatabase.self)
        var databases = DatabasesConfig()
        databases.add(database: MongoDatabase.self, as: .mongo)
        services.register(databases)
    }

    public func didBoot(_ worker: Container) throws -> EventLoopFuture<Void> {
        return .done(on: worker)
    }
}

/// MARK: Services

extension MongoDatabaseConfig: ServiceType {
    /// See `ServiceType.makeService(for:)`
    public static func makeService(for worker: Container) throws -> MongoDatabaseConfig {
        return try .init()
    }
}

extension MongoDatabase: ServiceType {
    /// See `ServiceType.makeService(for:)`
    public static func makeService(for worker: Container) throws -> MongoDatabase {
        return try .init(config: worker.make(), threadPool: worker.make())
    }
}

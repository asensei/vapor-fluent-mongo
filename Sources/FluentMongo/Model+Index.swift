//
//  Model+Index.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 21/12/2018.
//  Copyright © 2018 Asensei Inc. All rights reserved.
//

import Foundation
import Fluent

extension Model where Database == MongoDatabase {
    public static func index(on conn: Database.Connection) -> IndexBuilder<Self> {
        return IndexBuilder(on: conn.databaseConnection(to: Self.defaultDatabase))
    }

    public static func index(on conn: DatabaseConnectable) -> IndexBuilder<Self> {
        return IndexBuilder(on: conn.databaseConnection(to: Self.defaultDatabase))
    }
}

extension Future where T: Model, T.Database == MongoDatabase {

    @discardableResult
    public func mapIfDuplicatedKeyError(_ callback: @escaping (MongoConnection.Error) throws -> T) -> Future<T> {
        return self.catchMap { error in
            guard
                let mongoConnectionError = error as? MongoConnection.Error,
                case .duplicatedKey = mongoConnectionError
                else {
                    throw error
            }

            return try callback(mongoConnectionError)
        }
    }
}

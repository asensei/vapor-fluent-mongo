//
//  IndexBuilder.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 21/12/2018.
//  Copyright © 2018 Asensei Inc. All rights reserved.
//

import Foundation
import Fluent
import MongoSwift

public final class IndexBuilder<T: Model> {

    private var index: IndexModel

    public let connection: Future<MongoConnection>

    internal init(on connection: Future<MongoConnection>) {
        self.index = IndexModel(keys: [:])
        self.connection = connection
    }
}

extension IndexBuilder {

    public func create() -> Future<Void> {
        return self.connection.flatMap { conn in
            return conn.createIndex(self.index, in: T.entity)
        }
    }

    public func drop() -> Future<Void> {
        return self.connection.flatMap { conn in
            return conn.dropIndex(self.index, in: T.entity)
        }
    }
}

extension IndexBuilder {

    public func key<V>(_ key: KeyPath<T, V>, _ direction: FluentMongoQuerySortDirection = .ascending) -> IndexBuilder<T> {
        let property: FluentProperty = .keyPath(key)
        var keys = self.index.keys
        keys[property.path.joined(separator: ".")] = .init(direction.rawValue)
        self.index = IndexModel(keys: keys, options: self.index.options)

        return self
    }

    public func background(_ value: Bool) -> IndexBuilder<T> {
        var options = self.index.options ?? IndexOptions()
        options.background = value
        self.index = IndexModel(keys: self.index.keys, options: options)

        return self
    }

    public func expireAfter(_ value: Int32) -> IndexBuilder<T> {
        var options = self.index.options ?? IndexOptions()
        options.expireAfterSeconds = value
        self.index = IndexModel(keys: self.index.keys, options: options)

        return self
    }

    public func name(_ value: String) -> IndexBuilder<T> {
        var options = self.index.options ?? IndexOptions()
        options.name = value
        self.index = IndexModel(keys: self.index.keys, options: options)

        return self
    }

    public func unique(_ value: Bool) -> IndexBuilder<T> {
        var options = self.index.options ?? IndexOptions()
        options.unique = value
        self.index = IndexModel(keys: self.index.keys, options: options)

        return self
    }
}

public enum IndexBuilderError: Swift.Error {
    case invalidKeys
}

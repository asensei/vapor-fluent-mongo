//
//  IndexBuilder.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 21/12/2018.
//  Copyright © 2018 Asensei Inc. All rights reserved.
//

import Foundation
import FluentKit
import MongoSwift

public final class IndexBuilder<Model: FluentKit.Model> {

    private var index: IndexModel

    public let database: Database

    public required init(database: Database) {
        self.index = IndexModel(keys: [:])
        self.database = database
    }

    private convenience init(database: Database, index: IndexModel) {
        self.init(database: database)
        self.index = index
    }

    public func copy() -> IndexBuilder<Model> {
        .init(database: self.database, index: self.index)
    }
}

extension IndexBuilder {

    public func key<Key: QueryableProperty>(_ key: KeyPath<Model, Key>, _ direction: SortDirection = .ascending) -> Self where Key.Model == Model {
        return self.key(Model.init()[keyPath: key].path, direction)
    }

    public func key(_ keyName: FieldKey, _ direction: SortDirection = .ascending) -> Self {
        return self.key([keyName], direction)
    }

    public func key(_ keyNames: [FieldKey], _ direction: SortDirection = .ascending) -> Self {
        var keys = self.index.keys
        keys[keyNames.mongoKeys.dotNotation] = IndexType.sort(direction).bsonValue
        self.index = IndexModel(keys: keys, options: self.index.options)

        return self
    }
}

extension IndexBuilder {

    public func key<Key: QueryableProperty>(_ key: KeyPath<Model, Key>, _ type: IndexType = .sort(.ascending)) -> Self where Key.Model == Model {
        return self.key(Model.init()[keyPath: key].path, type)
    }

    public func key(_ keyName: FieldKey, _ type: IndexType = .sort(.ascending)) -> Self {
        return self.key([keyName], type)
    }

    public func key(_ keyNames: [FieldKey], _ type: IndexType = .sort(.ascending)) -> Self {
        var keys = self.index.keys
        keys[keyNames.mongoKeys.dotNotation] = type.bsonValue
        self.index = IndexModel(keys: keys, options: self.index.options)

        return self
    }

    public func background(_ value: Bool) -> Self {
        var options = self.index.options ?? IndexOptions()
        options.background = value
        self.index = IndexModel(keys: self.index.keys, options: options)

        return self
    }

    public func expireAfter(_ value: Int) -> Self {
        var options = self.index.options ?? IndexOptions()
        options.expireAfterSeconds = value
        self.index = IndexModel(keys: self.index.keys, options: options)

        return self
    }

    public func name(_ value: String) -> Self {
        var options = self.index.options ?? IndexOptions()
        options.name = value
        self.index = IndexModel(keys: self.index.keys, options: options)

        return self
    }

    public func unique(_ value: Bool) -> Self {
        var options = self.index.options ?? IndexOptions()
        options.unique = value
        self.index = IndexModel(keys: self.index.keys, options: options)

        return self
    }
}

extension IndexBuilder {

    public func create() -> EventLoopFuture<Void> {

        var query = Model.query(on: self.database).query
        query.action = .index(.create(self.index))

        return self.database.execute(query: query) { output in
            print(output)
        }
    }

    public func drop() -> EventLoopFuture<Void> {

        var query = Model.query(on: self.database).query
        query.action = .index(.delete(self.index))

        return self.database.execute(query: query) { output in
            print(output)
        }
    }
}

extension IndexBuilder {

    public enum IndexType {
        case sort(SortDirection)
        case text

        fileprivate var bsonValue: BSON {
            switch self {
            case .sort(let direction):
                return .init(direction.rawValue)
            case .text:
                return "text"
            }
        }
    }

    public enum SortDirection: Int {
        case ascending = 1
        case descending = -1
    }
}

extension Model {

    public static func index(on database: Database) -> IndexBuilder<Self> {
        .init(database: database)
    }
}

extension DatabaseQuery.Action {

    public enum MongoIndex {
        case create(IndexModel)
        case delete(IndexModel)
    }

    public static func index(_ action: MongoIndex) -> DatabaseQuery.Action {
        return .custom(action)
    }
}

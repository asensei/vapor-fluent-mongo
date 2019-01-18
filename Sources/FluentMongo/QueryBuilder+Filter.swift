//
//  QueryBuilder+Filter.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 18/01/2019.
//  Copyright © 2019 Asensei Inc. All rights reserved.
//

import Foundation
import Fluent

public extension QueryBuilder where Database == MongoDatabase {

    @discardableResult
    public func filter<C: Collection>(_ key: KeyPath<Result, C>, _ method: MongoDatabase.QueryFilterMethod, _ value: C.Element) -> Self
        where C.Element: Encodable
    {
        if value.isNil {
            return self.filter(custom: Database.queryFilter(Database.queryField(.keyPath(key)), method, Database.queryFilterValueNil))
        } else {
            return self.filter(custom: Database.queryFilter(Database.queryField(.keyPath(key)), method, Database.queryFilterValue([value])))
        }
    }

    @discardableResult
    public func filter<C: Collection>(_ key: KeyPath<Result, C?>, _ method: MongoDatabase.QueryFilterMethod, _ value: C.Element) -> Self
        where C.Element: Encodable
    {
        if value.isNil {
            return self.filter(custom: Database.queryFilter(Database.queryField(.keyPath(key)), method, Database.queryFilterValueNil))
        } else {
            return self.filter(custom: Database.queryFilter(Database.queryField(.keyPath(key)), method, Database.queryFilterValue([value])))
        }
    }

    @discardableResult
    public func filter<A, C: Collection>(_ key: KeyPath<A, C>, _ method: MongoDatabase.QueryFilterMethod, _ value: C.Element) -> Self
        where C.Element: Encodable
    {
        if value.isNil {
            return self.filter(custom: Database.queryFilter(Database.queryField(.keyPath(key)), method, Database.queryFilterValueNil))
        } else {
            return self.filter(custom: Database.queryFilter(Database.queryField(.keyPath(key)), method, Database.queryFilterValue([value])))
        }
    }

    @discardableResult
    public func filter<A, C: Collection>(_ key: KeyPath<A, C?>, _ method: MongoDatabase.QueryFilterMethod, _ value: C.Element) -> Self
        where C.Element: Encodable
    {
        if value.isNil {
            return self.filter(custom: Database.queryFilter(Database.queryField(.keyPath(key)), method, Database.queryFilterValueNil))
        } else {
            return self.filter(custom: Database.queryFilter(Database.queryField(.keyPath(key)), method, Database.queryFilterValue([value])))
        }
    }

    @discardableResult
    public func filter<C: Collection>(_ key: KeyPath<Result, C>, _ method: MongoDatabase.QueryFilterMethod, _ value: C) -> Self
        where C: Encodable, C.Element: Encodable
    {
        if value.isNil {
            return self.filter(custom: Database.queryFilter(Database.queryField(.keyPath(key)), method, Database.queryFilterValueNil))
        } else {
            return self.filter(custom: Database.queryFilter(Database.queryField(.keyPath(key)), method, self.queryFilterValue(value, for: method)))
        }
    }

    @discardableResult
    public func filter<C: Collection>(_ key: KeyPath<Result, C?>, _ method: MongoDatabase.QueryFilterMethod, _ value: C) -> Self
        where C: Encodable, C.Element: Encodable
    {
        if value.isNil {
            return self.filter(custom: Database.queryFilter(Database.queryField(.keyPath(key)), method, Database.queryFilterValueNil))
        } else {
            return self.filter(custom: Database.queryFilter(Database.queryField(.keyPath(key)), method, self.queryFilterValue(value, for: method)))
        }
    }

    @discardableResult
    public func filter<A, C: Collection>(_ key: KeyPath<A, C>, _ method: MongoDatabase.QueryFilterMethod, _ value: C) -> Self
        where C: Encodable, C.Element: Encodable
    {
        if value.isNil {
            return self.filter(custom: Database.queryFilter(Database.queryField(.keyPath(key)), method, Database.queryFilterValueNil))
        } else {
            return self.filter(custom: Database.queryFilter(Database.queryField(.keyPath(key)), method, self.queryFilterValue(value, for: method)))
        }
    }

    @discardableResult
    public func filter<A, C: Collection>(_ key: KeyPath<A, C?>, _ method: MongoDatabase.QueryFilterMethod, _ value: C) -> Self
        where C: Encodable, C.Element: Encodable
    {
        if value.isNil {
            return self.filter(custom: Database.queryFilter(Database.queryField(.keyPath(key)), method, Database.queryFilterValueNil))
        } else {
            return self.filter(custom: Database.queryFilter(Database.queryField(.keyPath(key)), method, self.queryFilterValue(value, for: method)))
        }
    }

    private func queryFilterValue<C: Collection>(_ value: C, for method: MongoDatabase.QueryFilterMethod) -> MongoDatabase.QueryFilterValue
        where C: Encodable, C.Element: Encodable
    {
        switch method {
        case .inSubset, .notInSubset:
            return Database.queryFilterValue(Array(value))
        default:
            return Database.queryFilterValue([value])
        }
    }
}

// MARK: Internal

internal extension Encodable {
    /// Returns `true` if this `Encodable` is `nil`.
    var isNil: Bool {
        guard let optional = self as? AnyOptionalType, optional.anyWrapped == nil else {
            return false
        }
        return true
    }
}

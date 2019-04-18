//
//  QueryBuilder+Operators.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 18/01/2019.
//  Copyright © 2019 Asensei Inc. All rights reserved.
//

import Foundation
import Fluent

extension QueryBuilder where Database == MongoDatabase {

    @discardableResult
    public func filter(_ value: FluentMongoFilterOperator<Database, Result>) -> Self {
        return self.filter(custom: value.filter)
    }

    @discardableResult
    public func filter<A>(_ value: FluentMongoFilterOperator<Database, A>) -> Self {
        return self.filter(custom: value.filter)
    }
}

public func ~~ <Database, Result, C: Collection>(lhs: KeyPath<Result, C>, rhs: C.Element) -> FluentMongoFilterOperator<Database, Result>
    where C: Encodable, C.Element: Encodable
{
    return FluentMongoFilterOperator.make(lhs, Database.queryFilterMethodInSubset, rhs)
}

public func ~~ <Database, Result, C: Collection>(lhs: KeyPath<Result, C?>, rhs: C.Element) -> FluentMongoFilterOperator<Database, Result>
    where C: Encodable, C.Element: Encodable
{
    return FluentMongoFilterOperator.make(lhs, Database.queryFilterMethodInSubset, rhs)
}

public func ~~ <Database, Result, C: Collection>(lhs: KeyPath<Result, C>, rhs: C) -> FluentMongoFilterOperator<Database, Result>
    where C: Encodable, C.Element: Encodable
{
    return FluentMongoFilterOperator.make(lhs, Database.queryFilterMethodInSubset, rhs)
}

public func ~~ <Database, Result, C: Collection>(lhs: KeyPath<Result, C?>, rhs: C) -> FluentMongoFilterOperator<Database, Result>
    where C: Encodable, C.Element: Encodable
{
    return FluentMongoFilterOperator.make(lhs, Database.queryFilterMethodInSubset, rhs)
}

public func !~ <Database, Result, C: Collection>(lhs: KeyPath<Result, C>, rhs: C.Element) -> FluentMongoFilterOperator<Database, Result>
    where C: Encodable, C.Element: Encodable
{
    return FluentMongoFilterOperator.make(lhs, Database.queryFilterMethodNotInSubset, rhs)
}

public func !~ <Database, Result, C: Collection>(lhs: KeyPath<Result, C?>, rhs: C.Element) -> FluentMongoFilterOperator<Database, Result>
    where C: Encodable, C.Element: Encodable
{
    return FluentMongoFilterOperator.make(lhs, Database.queryFilterMethodNotInSubset, rhs)
}

public func !~ <Database, Result, C: Collection>(lhs: KeyPath<Result, C>, rhs: C) -> FluentMongoFilterOperator<Database, Result>
    where C: Encodable, C.Element: Encodable
{
    return FluentMongoFilterOperator.make(lhs, Database.queryFilterMethodNotInSubset, rhs)
}

public func !~ <Database, Result, C: Collection>(lhs: KeyPath<Result, C?>, rhs: C) -> FluentMongoFilterOperator<Database, Result>
    where C: Encodable, C.Element: Encodable
{
    return FluentMongoFilterOperator.make(lhs, Database.queryFilterMethodNotInSubset, rhs)
}

public struct FluentMongoFilterOperator<Database, Result> where Database: QuerySupporting {
    /// The wrapped query filter method.
    fileprivate let filter: Database.QueryFilter

    /// Operator helper func.
    fileprivate static func make<C: Collection>(_ key: KeyPath<Result, C>, _ method: Database.QueryFilterMethod, _ value: C.Element) -> FluentMongoFilterOperator<Database, Result>
        where C: Encodable, C.Element: Encodable
    {
        if value.isNil {
            return FluentMongoFilterOperator<Database, Result>(
                filter: Database.queryFilter(Database.queryField(.keyPath(key)), method, Database.queryFilterValueNil)
            )
        } else {
            return FluentMongoFilterOperator<Database, Result>(
                filter: Database.queryFilter(Database.queryField(.keyPath(key)), method, Database.queryFilterValue([value]))
            )
        }
    }

    /// Operator helper func.
    fileprivate static func make<C: Collection>(_ key: KeyPath<Result, C?>, _ method: Database.QueryFilterMethod, _ value: C.Element) -> FluentMongoFilterOperator<Database, Result>
        where C: Encodable, C.Element: Encodable
    {
        if value.isNil {
            return FluentMongoFilterOperator<Database, Result>(
                filter: Database.queryFilter(Database.queryField(.keyPath(key)), method, Database.queryFilterValueNil)
            )
        } else {
            return FluentMongoFilterOperator<Database, Result>(
                filter: Database.queryFilter(Database.queryField(.keyPath(key)), method, Database.queryFilterValue([value]))
            )
        }
    }

    /// Operator helper func.
    fileprivate static func make<C: Collection>(_ key: KeyPath<Result, C>, _ method: Database.QueryFilterMethod, _ value: C) -> FluentMongoFilterOperator<Database, Result>
        where C: Encodable, C.Element: Encodable
    {
        if value.count == 1, let value = value.first, value.isNil {
            return FluentMongoFilterOperator<Database, Result>(
                filter: Database.queryFilter(Database.queryField(.keyPath(key)), method, Database.queryFilterValueNil)
            )
        } else {
            return FluentMongoFilterOperator<Database, Result>(
                filter: Database.queryFilter(Database.queryField(.keyPath(key)), method, Database.queryFilterValue(Array(value)))
            )
        }
    }

    /// Operator helper func.
    fileprivate static func make<C: Collection>(_ key: KeyPath<Result, C?>, _ method: Database.QueryFilterMethod, _ value: C) -> FluentMongoFilterOperator<Database, Result>
        where C: Encodable, C.Element: Encodable
    {
        if value.count == 1, let value = value.first, value.isNil {
            return FluentMongoFilterOperator<Database, Result>(
                filter: Database.queryFilter(Database.queryField(.keyPath(key)), method, Database.queryFilterValueNil)
            )
        } else {
            return FluentMongoFilterOperator<Database, Result>(
                filter: Database.queryFilter(Database.queryField(.keyPath(key)), method, Database.queryFilterValue(Array(value)))
            )
        }
    }
}

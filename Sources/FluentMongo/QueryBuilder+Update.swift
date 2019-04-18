//
//  QueryBuilder+Update.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 31/01/2019.
//  Copyright © 2019 Asensei Inc. All rights reserved.
//

import Foundation
import Fluent

extension QueryBuilder where Database == MongoDatabase, Result: Model {

    /// Adds elements to an array only if they do not already exist in the set.
    public func update<C>(_ field: KeyPath<Result, C>, addToSet values: C) -> Self where C: Collection & Encodable, C.Element: Encodable {
        Database.queryActionApply(Database.queryActionUpdate, to: &query)

        var dummyQuery = Database.query(Database.queryEntity(for: query))
        Database.queryDataSet(Database.queryField(.keyPath(field)), to: values, on: &dummyQuery)

        if let partialData = dummyQuery.partialData {
            var partialCustomData = query.partialCustomData ?? FluentMongoQueryData()
            partialCustomData["$addToSet"] = partialData.mapValues { ["$each": $0] as FluentMongoQueryData }
            query.partialCustomData = partialCustomData
        }

        if let updatedAtKey = Result.updatedAtKey {
            Database.queryDataSet(Database.queryField(.keyPath(updatedAtKey)), to: Date(), on: &query)
        }

        return self
    }

    /// Adds elements to an array only if they do not already exist in the set.
    public func update<C>(_ field: KeyPath<Result, C?>, addToSet values: C) -> Self where C: Collection & Encodable, C.Element: Encodable {
        Database.queryActionApply(Database.queryActionUpdate, to: &query)

        var dummyQuery = Database.query(Database.queryEntity(for: query))
        Database.queryDataSet(Database.queryField(.keyPath(field)), to: values, on: &dummyQuery)

        if let partialData = dummyQuery.partialData {
            var partialCustomData = query.partialCustomData ?? FluentMongoQueryData()
            partialCustomData["$addToSet"] = partialData.mapValues { ["$each": $0] as FluentMongoQueryData }
            query.partialCustomData = partialCustomData
        }

        if let updatedAtKey = Result.updatedAtKey {
            Database.queryDataSet(Database.queryField(.keyPath(updatedAtKey)), to: Date(), on: &query)
        }

        return self
    }

    /// Adds elements to an array.
    public func update<C>(_ field: KeyPath<Result, C>, push values: C) -> Self where C: Collection & Encodable, C.Element: Encodable {
        Database.queryActionApply(Database.queryActionUpdate, to: &query)

        var dummyQuery = Database.query(Database.queryEntity(for: query))
        Database.queryDataSet(Database.queryField(.keyPath(field)), to: values, on: &dummyQuery)

        if let partialData = dummyQuery.partialData {
            var partialCustomData = query.partialCustomData ?? FluentMongoQueryData()
            partialCustomData["$push"] = partialData.mapValues { ["$each": $0] as FluentMongoQueryData }
            query.partialCustomData = partialCustomData
        }

        if let updatedAtKey = Result.updatedAtKey {
            Database.queryDataSet(Database.queryField(.keyPath(updatedAtKey)), to: Date(), on: &query)
        }

        return self
    }

    /// Adds elements to an array.
    public func update<C>(_ field: KeyPath<Result, C?>, push values: C) -> Self where C: Collection & Encodable, C.Element: Encodable {
        Database.queryActionApply(Database.queryActionUpdate, to: &query)

        var dummyQuery = Database.query(Database.queryEntity(for: query))
        Database.queryDataSet(Database.queryField(.keyPath(field)), to: values, on: &dummyQuery)

        if let partialData = dummyQuery.partialData {
            var partialCustomData = query.partialCustomData ?? FluentMongoQueryData()
            partialCustomData["$push"] = partialData.mapValues { ["$each": $0] as FluentMongoQueryData }
            query.partialCustomData = partialCustomData
        }

        if let updatedAtKey = Result.updatedAtKey {
            Database.queryDataSet(Database.queryField(.keyPath(updatedAtKey)), to: Date(), on: &query)
        }

        return self
    }

    /// Removes all matching values from an array.
    public func update<C>(_ field: KeyPath<Result, C>, pullAll values: C) -> Self where C: Collection & Encodable, C.Element: Encodable {
        Database.queryActionApply(Database.queryActionUpdate, to: &query)

        var dummyQuery = Database.query(Database.queryEntity(for: query))
        Database.queryDataSet(Database.queryField(.keyPath(field)), to: values, on: &dummyQuery)

        if let partialData = dummyQuery.partialData {
            var partialCustomData = query.partialCustomData ?? FluentMongoQueryData()
            partialCustomData["$pullAll"] = partialData
            query.partialCustomData = partialCustomData
        }

        if let updatedAtKey = Result.updatedAtKey {
            Database.queryDataSet(Database.queryField(.keyPath(updatedAtKey)), to: Date(), on: &query)
        }

        return self
    }

    /// Removes all matching values from an array.
    public func update<C>(_ field: KeyPath<Result, C?>, pullAll values: C) -> Self where C: Collection & Encodable, C.Element: Encodable {
        Database.queryActionApply(Database.queryActionUpdate, to: &query)

        var dummyQuery = Database.query(Database.queryEntity(for: query))
        Database.queryDataSet(Database.queryField(.keyPath(field)), to: values, on: &dummyQuery)

        if let partialData = dummyQuery.partialData {
            var partialCustomData = query.partialCustomData ?? FluentMongoQueryData()
            partialCustomData["$pullAll"] = partialData
            query.partialCustomData = partialCustomData
        }

        if let updatedAtKey = Result.updatedAtKey {
            Database.queryDataSet(Database.queryField(.keyPath(updatedAtKey)), to: Date(), on: &query)
        }

        return self
    }
}

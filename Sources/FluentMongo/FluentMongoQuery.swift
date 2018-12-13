//
//  FluentMongoQuery.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 04/12/2018.
//  Copyright © 2018 Asensei Inc. All rights reserved.
//

import Foundation
import Fluent

// MARK: - Query

public struct FluentMongoQuery {
    public var collection: String
    public var action: FluentMongoQueryAction
    public var projection: Document?
    public var filter: FluentMongoQueryFilter?
    public var defaultFilterRelation: FluentMongoQueryFilterRelation
    public var aggregate: FluentMongoQueryAggregate?
    public var data: Document?
    public var skip: Int64?
    public var limit: Int64?

    public init(
        collection: String,
        action: FluentMongoQueryAction = .find,
        projection: Document? = nil,
        filter: FluentMongoQueryFilter? = nil,
        defaultFilterRelation: FluentMongoQueryFilterRelation = .and,
        aggregate: FluentMongoQueryAggregate? = nil,
        data: Document? = nil,
        skip: Int64? = nil,
        limit: Int64? = nil
        ) {
        self.collection = collection
        self.action = action
        self.projection = projection
        self.filter = filter
        self.defaultFilterRelation = defaultFilterRelation
        self.aggregate = aggregate
        self.data = data
        self.skip = skip
        self.limit = limit
    }
}

extension Database where Self: QuerySupporting, Self.Query == FluentMongoQuery {

    public static func query(_ entity: String) -> FluentMongoQuery {
        return FluentMongoQuery(collection: entity)
    }

    public static func queryEntity(for query: FluentMongoQuery) -> String {
        return query.collection
    }

    public static func queryRangeApply(lower: Int, upper: Int?, to query: inout Query) {
        query.skip = Int64(lower)

        if let upper = upper {
            query.limit = Int64(upper - lower)
        }
    }
}

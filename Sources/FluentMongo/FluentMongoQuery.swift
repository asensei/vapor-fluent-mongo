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
    public var filter: FluentMongoQueryFilter?
    public var defaultFilterRelation: FluentMongoQueryFilterRelation
    public var aggregate: FluentMongoQueryAggregate?
    public var data: Document?

    public init(
        collection: String,
        action: FluentMongoQueryAction = .find,
        filter: FluentMongoQueryFilter? = nil,
        defaultFilterRelation: FluentMongoQueryFilterRelation = .and,
        aggregate: FluentMongoQueryAggregate? = nil,
        data: Document? = nil
        ) {
        self.collection = collection
        self.action = action
        self.filter = filter
        self.defaultFilterRelation = defaultFilterRelation
        self.aggregate = aggregate
        self.data = data
    }
}

extension Database where Self: QuerySupporting, Self.Query == FluentMongoQuery {

    public static func query(_ entity: String) -> FluentMongoQuery {
        return FluentMongoQuery(collection: entity)
    }

    public static func queryEntity(for query: FluentMongoQuery) -> String {
        return query.collection
    }
}

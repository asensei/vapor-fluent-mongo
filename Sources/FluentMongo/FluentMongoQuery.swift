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
    public var keys: [FluentMongoQueryKey]
    public var filter: FluentMongoQueryFilter?
    public var defaultFilterRelation: FluentMongoQueryFilterRelation
    public var data: Document?
    public var skip: Int64?
    public var limit: Int64?

    public init(
        collection: String,
        action: FluentMongoQueryAction = .find,
        keys: [FluentMongoQueryKey] = [],
        filter: FluentMongoQueryFilter? = nil,
        defaultFilterRelation: FluentMongoQueryFilterRelation = .and,
        data: Document? = nil,
        skip: Int64? = nil,
        limit: Int64? = nil
        ) {
        self.collection = collection
        self.action = action
        self.keys = keys
        self.filter = filter
        self.defaultFilterRelation = defaultFilterRelation
        self.data = data
        self.skip = skip
        self.limit = limit
    }

    func aggregationPipeline() -> [Document] {
        guard self.action == .find else {
            return []
        }

        var pipeline = [Document]()

        if let filter = self.filter {
            pipeline.append(["$match": filter])
        }

        // Projection
        var projection = Document()
        for key in self.keys {
            guard case .raw(let field) = key else {
                continue
            }

            projection[field] = 1
        }
        if !projection.isEmpty {
            pipeline.append(["$project": projection])
        }

        /* Sort
         if let sort = query.sort {

         }*/

        // Skip
        if let skip = self.skip {
            pipeline.append(["$skip": skip])
        }

        // Limit
        if let limit = self.limit {
            pipeline.append(["$limit": limit])
        }

        // Aggregate
        for key in self.keys {
            guard case .computed(let aggregate, let keys) = key else {
                continue
            }

            switch aggregate {
            case .count:
                pipeline.append([aggregate.value: "fluentAggregate"])
            case .group(let accumulator):
                var group: Document = ["_id": nil]
                for key in keys {
                    guard case .raw(let field) = key else {
                        continue
                    }
                    // It seems that fluent only support one aggregated field
                    group["fluentAggregate"] = [accumulator.value: "$" + field] as Document
                    break
                }

                pipeline.append([aggregate.value: group])
            }
        }

        return pipeline
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

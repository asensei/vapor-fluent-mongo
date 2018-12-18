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

    public static let defaultAggregateField: String = "fluentAggregate"

    public var collection: String
    public var action: FluentMongoQueryAction
    public var keys: [FluentMongoQueryKey]
    public var filter: FluentMongoQueryFilter?
    public var defaultFilterRelation: FluentMongoQueryFilterRelation
    public var data: FluentMongoQueryData?
    public var partialData: FluentMongoQueryData?
    public var skip: Int64?
    public var limit: Int64?

    public init(
        collection: String,
        action: FluentMongoQueryAction = .find,
        keys: [FluentMongoQueryKey] = [],
        filter: FluentMongoQueryFilter? = nil,
        defaultFilterRelation: FluentMongoQueryFilterRelation = .and,
        data: FluentMongoQueryData? = nil,
        partialData: FluentMongoQueryData? = nil,
        skip: Int64? = nil,
        limit: Int64? = nil
        ) {
        self.collection = collection
        self.action = action
        self.keys = keys
        self.filter = filter
        self.defaultFilterRelation = defaultFilterRelation
        self.data = data
        self.partialData = partialData
        self.skip = skip
        self.limit = limit
    }

    func projection() -> Document? {
        var projection = Document()
        for key in self.keys {
            guard case .raw(let field) = key else {
                continue
            }

            projection[field] = 1
        }

        guard !projection.isEmpty else {
            return nil
        }

        return projection
    }

    func aggregates() -> [Document]? {
        var aggregates = [Document]()

        for key in self.keys {
            guard case .computed(let aggregate, let keys) = key else {
                continue
            }

            switch aggregate {
            case .count:
                aggregates.append([aggregate.value: FluentMongoQuery.defaultAggregateField])
            case .group(let accumulator):
                var group: Document = ["_id": NSNull()]
                for key in keys {
                    guard case .raw(let field) = key else {
                        continue
                    }
                    // It seems that fluent only support one aggregated field
                    group[FluentMongoQuery.defaultAggregateField] = [accumulator.value: "$" + field] as Document
                    break
                }

                aggregates.append([aggregate.value: group])
            }
        }

        return aggregates.isEmpty ? nil : aggregates
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
        if let projection = self.projection() {
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

        // Aggregates
        if let aggregates = self.aggregates() {
            pipeline.append(contentsOf: aggregates)
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

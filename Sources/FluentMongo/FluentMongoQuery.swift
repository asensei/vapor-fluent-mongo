//
//  FluentMongoQuery.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 04/12/2018.
//  Copyright © 2018 Asensei Inc. All rights reserved.
//

import Foundation
import Fluent
import MongoSwift

// MARK: - Query

public struct FluentMongoQuery {

    public static let defaultAggregateField: String = "fluentAggregate"

    public var collection: String
    public var action: FluentMongoQueryAction
    public var keys: [FluentMongoQueryKey]
    public var isDistinct: Bool
    public var joins: FluentMongoQueryJoin
    public var filter: FluentMongoQueryFilter?
    public var defaultFilterRelation: FluentMongoQueryFilterRelation
    public var data: FluentMongoQueryData?
    public var partialData: FluentMongoQueryData?
    public var partialCustomData: FluentMongoQueryData?
    public var skip: Int64?
    public var limit: Int64?
    public var sort: FluentMongoQuerySort?

    public var aggregateOptions: AggregateOptions?

    public init(
        collection: String,
        action: FluentMongoQueryAction = .find,
        keys: [FluentMongoQueryKey] = [],
        isDistinct: Bool = false,
        joins: FluentMongoQueryJoin = [],
        filter: FluentMongoQueryFilter? = nil,
        defaultFilterRelation: FluentMongoQueryFilterRelation = .and,
        data: FluentMongoQueryData? = nil,
        partialData: FluentMongoQueryData? = nil,
        partialCustomData: FluentMongoQueryData? = nil,
        skip: Int64? = nil,
        limit: Int64? = nil,
        sort: FluentMongoQuerySort? = nil,
        aggregateOptions: AggregateOptions? = nil
        ) {
        self.collection = collection
        self.action = action
        self.keys = keys
        self.isDistinct = isDistinct
        self.joins = joins
        self.filter = filter
        self.defaultFilterRelation = defaultFilterRelation
        self.data = data
        self.partialData = partialData
        self.partialCustomData = partialCustomData
        self.skip = skip
        self.limit = limit
        self.sort = sort
        self.aggregateOptions = aggregateOptions
    }

    func projection() -> Document? {
        var projection = Document()
        for key in self.keys {
            guard case .raw(let field) = key else {
                continue
            }

            projection[(field.entity == self.collection ? field.path : field.pathWithNamespace).joined(separator: ".")] = true
        }

        guard !projection.isEmpty else {
            return nil
        }

        projection["_id"] = true

        return projection
    }

    func distinct() -> [Document] {
        var stages = [Document]()
        var group = Document()
        var id = Document()
        for key in self.keys {
            guard case .raw(let field) = key else {
                continue
            }
            // It is not possible to use dots when specifying an id field for $group
            let path = (field.entity == self.collection ? field.path : field.pathWithNamespace)
            id[field.pathWithNamespace.joined(separator: ":")] = .string("$" + path.joined(separator: "."))
        }

        if id.isEmpty {
            id[self.collection + ":_id"] = "$_id"
        }

        group["_id"] = .document(id)
        group["doc"] = ["$first": "$$ROOT"]

        stages.append(["$group": .document(group)])
        stages.append(["$replaceRoot": ["newRoot": "$doc"]])

        return stages
    }

    func aggregates() -> [Document]? {
        var aggregates = [Document]()

        for key in self.keys {
            guard case .computed(let aggregate, let keys) = key else {
                continue
            }

            switch aggregate {
            case .count:
                aggregates.append([aggregate.value: .string(FluentMongoQuery.defaultAggregateField)])
            case .group(let accumulator):
                var group: Document = ["_id": .null]
                for key in keys {
                    guard case .raw(let field) = key else {
                        continue
                    }
                    // It seems that fluent only support one aggregated field
                    let path = (field.entity == self.collection ? field.path : field.pathWithNamespace).joined(separator: ".")
                    group[FluentMongoQuery.defaultAggregateField] = [accumulator.value: .string("$" + path)]
                    break
                }

                aggregates.append([aggregate.value: .document(group)])
            }
        }

        return aggregates.isEmpty ? nil : aggregates
    }

    func aggregationPipeline() -> [Document] {
        var pipeline = [Document]()

        // Joins
        if !self.joins.isEmpty {
            pipeline.append(contentsOf: self.joins)
        }

        // Filters
        if let filter = self.filter {
            pipeline.append(["$match": .document(filter)])
        }

        // Projection
        if let projection = self.projection() {
            pipeline.append(["$project": .document(projection)])
        }

        // Distinct
        if self.isDistinct {
            pipeline.append(contentsOf: self.distinct())
        }

        // Sort
        if let sort = self.sort {
            pipeline.append(["$sort": .document(sort)])
        }

        // Skip
        if let skip = self.skip {
            pipeline.append(["$skip": .int64(skip)])
        }

        // Limit
        if let limit = self.limit {
            pipeline.append(["$limit": .int64(limit)])
        }

        // Aggregates
        if let aggregates = self.aggregates() {
            pipeline.append(contentsOf: aggregates)
        }

        // Remove joined collections from the output
        if !self.joins.isEmpty {
            var projection = Document()
            for join in self.joins {
                guard let field = join["$lookup", "as"]?.stringValue else {
                    continue
                }

                projection[field] = false
            }
            pipeline.append(["$project": .document(projection)])
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

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
        sort: FluentMongoQuerySort? = nil
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
    }

    func projection() -> Document? {
        var projection = Document()
        for key in self.keys {
            guard case .raw(let field) = key else {
                continue
            }

            projection[field.pathWithNamespace.joined(separator: ".")] = true
        }

        guard !projection.isEmpty else {
            return nil
        }

        projection[self.collection + "._id"] = true

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
            id[field.pathWithNamespace.joined(separator: ":")] = "$" + field.pathWithNamespace.joined(separator: ".")
        }

        if id.isEmpty {
            id[self.collection + ":_id"] = "$" + self.collection + "._id"
        }

        group["_id"] = id
        group["doc"] = ["$first": "$" + self.collection] as Document

        stages.append(["$group": group])
        stages.append(["$project": [self.collection: "$doc"] as Document])

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
                aggregates.append([aggregate.value: FluentMongoQuery.defaultAggregateField])
            case .group(let accumulator):
                var group: Document = ["_id": BSONNull()]
                for key in keys {
                    guard case .raw(let field) = key else {
                        continue
                    }
                    // It seems that fluent only support one aggregated field
                    group[FluentMongoQuery.defaultAggregateField] = [accumulator.value: "$" + field.pathWithNamespace.joined(separator: ".")] as Document
                    break
                }

                aggregates.append([aggregate.value: group])
            }
        }

        return aggregates.isEmpty ? nil : aggregates
    }

    func aggregationPipeline() -> [Document] {
        var pipeline = [Document]()

        // Namespace root document
        pipeline.append(["$project": [self.collection: "$$ROOT"] as Document])

        // Joins
        if !self.joins.isEmpty {
            pipeline.append(contentsOf: self.joins)
        }

        // Filters
        if let filter = self.filter {
            pipeline.append(["$match": filter])
        }

        // Projection
        if let projection = self.projection() {
            pipeline.append(["$project": projection])
        }

        // Distinct
        if self.isDistinct {
            pipeline.append(contentsOf: self.distinct())
        }

        // Sort
        if let sort = self.sort {
            pipeline.append(["$sort": sort])
        }

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
        } else {
            // Remove namespace
            pipeline.append(["$replaceRoot": ["newRoot": "$" + self.collection] as Document])
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

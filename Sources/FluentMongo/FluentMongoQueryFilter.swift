//
//  FluentMongoQueryFilter.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 11/12/2018.
//  Copyright © 2018 Asensei Inc. All rights reserved.
//

import Foundation
import Fluent
import MongoSwift

// MARK: - QueryFilter

public typealias FluentMongoQueryFilter = Document

extension Database where Self: QuerySupporting, Self.QueryFilter == FluentMongoQueryFilter, Self.QueryField == FluentProperty, Self.QueryFilterMethod == FluentMongoQueryFilterMethod, Self.QueryFilterValue == FluentMongoQueryFilterValue? {

    public static func queryFilter(_ field: QueryField, _ method: QueryFilterMethod, _ value: QueryFilterValue) -> QueryFilter {
        var document = Document()
        document[field.path] = [method.rawValue: value] as Document

        return document
    }
}

extension Database where Self: QuerySupporting, Self.Query == FluentMongoQuery, Self.QueryFilter == FluentMongoQueryFilter {

    public static func queryFilters(for query: Query) -> [QueryFilter] {
        guard let filter = query.filter else {
            return []
        }

        return [filter]
    }

    public static func queryFilterApply(_ filter: QueryFilter, to query: inout Query) {
        query.filter = filter
    }
}

// MARK: - QueryFilterMethod

public enum FluentMongoQueryFilterMethod: String {
    case equal = "$eq"
    case notEqual = "$ne"
    case greaterThan = "$gt"
    case lessThan = "$lt"
    case greaterThanOrEqual = "$gte"
    case lessThanOrEqual = "$lte"
    case inSubset = "$in"
    case notInSubset = "$nin"
}

extension Database where Self: QuerySupporting, Self.QueryFilterMethod == FluentMongoQueryFilterMethod {

    public static var queryFilterMethodEqual: QueryFilterMethod {
        return .equal
    }

    public static var queryFilterMethodNotEqual: QueryFilterMethod {
        return .notEqual
    }

    public static var queryFilterMethodGreaterThan: QueryFilterMethod {
        return .greaterThan
    }

    public static var queryFilterMethodLessThan: QueryFilterMethod {
        return .lessThan
    }

    public static var queryFilterMethodGreaterThanOrEqual: QueryFilterMethod {
        return .greaterThanOrEqual
    }

    public static var queryFilterMethodLessThanOrEqual: QueryFilterMethod {
        return .lessThanOrEqual
    }

    public static var queryFilterMethodInSubset: QueryFilterMethod {
        return .inSubset
    }

    public static var queryFilterMethodNotInSubset: QueryFilterMethod {
        return .notInSubset
    }
}

// MARK: - QueryFilterValue

public typealias FluentMongoQueryFilterValue = BSONValue

extension Database where Self: QuerySupporting, Self.QueryFilterValue == FluentMongoQueryFilterValue? {

    public static func queryFilterValue<E: Encodable>(_ encodables: [E]) -> QueryFilterValue {
        let encoder = BSONEncoder()
        let value: [BSONValue?] = encodables.map { encoder.encode($0) }

        return value
    }

    public static var queryFilterValueNil: QueryFilterValue {
        return nil
    }
}

// MARK: - QueryFilterRelation

public enum FluentMongoQueryFilterRelation: String {
    case and = "$and"
    case or = "$or"
}

extension Database where Self: QuerySupporting, Self.QueryFilterRelation == FluentMongoQueryFilterRelation {

    public static var queryFilterRelationAnd: QueryFilterRelation {
        return .and
    }

    public static var queryFilterRelationOr: QueryFilterRelation {
        return .or
    }
}

extension Database where Self: QuerySupporting, Self.QueryFilter == FluentMongoQueryFilter, Self.QueryFilterRelation == FluentMongoQueryFilterRelation {

    public static func queryFilterGroup(_ relation: QueryFilterRelation, _ filters: [QueryFilter]) -> QueryFilter {
        return [relation.rawValue: filters]
    }
}

extension Database where Self: QuerySupporting, Self.Query == FluentMongoQuery, Self.QueryFilterRelation == FluentMongoQueryFilterRelation {

    public static func queryDefaultFilterRelation(_ relation: QueryFilterRelation, on: inout Query) {
        on.defaultFilterRelation = relation
    }
}

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

extension Database where Self: QuerySupporting, Self.QueryFilter == FluentMongoQueryFilter, Self.QueryField == FluentMongoQueryField, Self.QueryFilterMethod == FluentMongoQueryFilterMethod, Self.QueryFilterValue == FluentMongoQueryFilterValue? {

    public static func queryFilter(_ field: QueryField, _ method: QueryFilterMethod, _ value: QueryFilterValue) -> QueryFilter {
        var document = Document()

        let unwrappedValue: BSON

        switch method {
        case .equal,
             .greaterThan,
             .greaterThanOrEqual,
             .lessThan,
             .lessThanOrEqual,
             .notEqual:
            unwrappedValue = value?.first ?? .null
        case .inSubset, .notInSubset:
            unwrappedValue = value.map { .array($0) } ?? .array([])
        }

        document[field.pathWithNamespace.joined(separator: ".")] = [method.rawValue: unwrappedValue]

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

        let filterByRemovingRootNamespace = filter.byRemovingKeysPrefix(query.collection)

        switch query.filter {
        case .some(let document):
            query.filter = [query.defaultFilterRelation.rawValue: [.document(document), .document(filterByRemovingRootNamespace)]]
        case .none:
            query.filter = filterByRemovingRootNamespace
        }
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

public typealias FluentMongoQueryFilterValue = [BSON]

extension Database where Self: BSONCoder, Self: QuerySupporting, Self.QueryFilterValue == FluentMongoQueryFilterValue? {

    public static func queryFilterValue<E: Encodable>(_ encodables: [E]) -> QueryFilterValue {
        let encoder = Self.encoder
        let value: [BSON] = encodables.compactMap { try? encoder.encodeBSONValue($0) }

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
        guard filters.count >= 2 else {
            return filters.first ?? [:]
        }

        return [relation.rawValue: .array(filters.map { .document($0) })]
    }
}

extension Database where Self: QuerySupporting, Self.Query == FluentMongoQuery, Self.QueryFilterRelation == FluentMongoQueryFilterRelation {

    public static func queryDefaultFilterRelation(_ relation: QueryFilterRelation, on: inout Query) {
        on.defaultFilterRelation = relation
    }
}

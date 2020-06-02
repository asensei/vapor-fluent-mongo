//
//  DatabaseQueryFilter+Mongo.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 21/05/2020.
//  Copyright © 2020 Asensei Inc. All rights reserved.
//

import Foundation
import FluentKit

extension DatabaseQuery.Filter {

    func mongoFilter(mainSchema: String, encoder: BSONEncoder) throws -> Document? {
        switch self {
        case .value(let field, let method, let value):
            let key = try field.mongoKeyPath(namespace: field.schema != mainSchema)
            let mongoOperator = try method.mongoOperator()
            let bsonValue = try value.mongoValue(encoder: encoder)

            return [key: [mongoOperator: bsonValue]]
        case .field(let lhs, let method, let rhs):
            let lhsKey: BSON = try .string("$" + lhs.mongoKeyPath(namespace: lhs.schema != mainSchema))
            let rhsKey: BSON = try .string("$" + rhs.mongoKeyPath(namespace: rhs.schema != mainSchema))
            let mongoOperator = try method.mongoOperator()

            return ["$expr": [mongoOperator: .array([lhsKey, rhsKey])]]
        case .group(let filters, let relation):
            let filters = try filters.compactMap { try $0.mongoFilter(mainSchema: mainSchema, encoder: encoder) }

            return try relation.mongoGroup(filters: filters)
        case .custom(let document as Document):
            return document
        case .custom:
            throw Error.unsupportedFilter
        }
    }
}

extension Array where Element == DatabaseQuery.Filter {

    func mongoMatch(mainSchema: String, encoder: BSONEncoder) throws -> [Document] {

         let filters = try self.compactMap { filter in
             try filter.mongoFilter(mainSchema: mainSchema, encoder: encoder)
         }

        guard let group = try DatabaseQuery.Filter.Relation.and.mongoGroup(filters: filters) else {
            return []
        }

        return [["$match": .document(group)]]
    }
}

extension DatabaseQuery.Filter.Method {

    func mongoOperator() throws -> String {
        switch self {
        case .equality(let inverse):
            return inverse ? "$ne" : "$eq"
        case .order(let inverse, let equality):
            switch (inverse, equality) {
            case (true, true):
                return "$lte"
            case (true, false):
                return "$lt"
            case (false, true):
                return "$gte"
            case (false, false):
                return "$gt"
            }
        case .subset(let inverse):
            return inverse ? "$nin" : "$in"
        case .contains(let inverse, _):
            return inverse ? "$nin" : "$in"
        case .custom(let value as String):
            return value
        default:
            throw Error.unsupportedOperator
        }
    }
}

extension DatabaseQuery.Filter.Relation {

    func mongoOperator() throws -> String {
        switch self {
        case .and:
            return "$and"
        case .or:
            return "$or"
        case .custom(let value as String):
            return value
        case .custom:
            throw Error.unsupportedFilterRelation
        }
    }

    func mongoGroup(filters: [Document]) throws -> Document? {
        switch filters.count {
        case 0:
            return nil
        case 1:
            return filters.first
        default:
            return [try self.mongoOperator(): .array(filters.map { .document($0) })]
        }
    }
}

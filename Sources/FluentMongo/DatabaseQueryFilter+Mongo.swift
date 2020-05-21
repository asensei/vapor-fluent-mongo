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

    func mongoFilter(aggregate: Bool, mainSchema: String, encoder: BSONEncoder) throws -> Document {
        switch self {
        case .value(let field, let method, let value):
            #warning("TODO: check if we need path or pathWithNamespace - related to byRemovingKeysPrefix")
            let key = try field.mongoKeyPath(namespace: aggregate)
            let mongoOperator = try method.mongoOperator()
            let bsonValue = try value.mongoValue(encoder: encoder)

            return [key: [mongoOperator: bsonValue]]
        case .field(let lhs, let method, let rhs):
            let lhsKey: BSON = try .string("$" + lhs.mongoKeyPath(namespace: lhs.schema != mainSchema))
            let rhsKey: BSON = try .string("$" + rhs.mongoKeyPath(namespace: rhs.schema != mainSchema))
            let mongoOperator = try method.mongoOperator()

            return ["$expr": [mongoOperator: .array([lhsKey, rhsKey])]]
        case .group(let filters, let relation):
            let filters = try filters.map { try $0.mongoFilter(aggregate: aggregate, mainSchema: mainSchema, encoder: encoder) }

            return try relation.mongoGroup(filters: filters)
        case .custom(let document as Document):
            return document
        case .custom:
            throw Error.unsupportedFilter
        }
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
        case .contains(let inverse, let location):
            #warning("TODO: implement this")
            throw Error.unsupportedOperator
        case .custom(let value as String):
            return value
        default:
            #warning("TODO: implement this")
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

    func mongoGroup(filters: [Document]) throws -> Document {
        return [try self.mongoOperator(): .array(filters.map { .document($0) })]
    }
}

//
//  DatabaseQueryJoin+Mongo.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 21/05/2020.
//  Copyright © 2020 Asensei Inc. All rights reserved.
//

import Foundation
import FluentKit

extension DatabaseQuery.Join {

    func mongoLookup() throws -> [BSONDocument] {
        switch self {
        case .join(let schema, let alias, let method, let foreign, let local):
            return try self._lookup(schema: schema, alias: alias, method: method, foreign: foreign, local: local)
        case .extendedJoin(let schema, .none, let alias, let method, let foreign, let local):
            return try self._lookup(schema: schema, alias: alias, method: method, foreign: foreign, local: local)
        case .extendedJoin, .custom:
            throw Error.unsupportedJoin
        }
    }

    private func _lookup(
        schema: String,
        alias: String?,
        method: Method,
        foreign: DatabaseQuery.Field,
        local: DatabaseQuery.Field
    ) throws -> [BSONDocument] {

        let lookup: BSONDocument = [
            "$lookup": [
                "from": .string(schema),
                "localField": .string(try local.mongoKeyPath()),
                "foreignField": .string(try foreign.mongoKeyPath()),
                "as": .string(alias ?? schema)
            ]
        ]

        func unwind(preserveNullAndEmptyArrays: Bool) -> BSONDocument {
            return [
                "$unwind": [
                    "path": .string("$" + (alias ?? schema)),
                    "preserveNullAndEmptyArrays": .bool(preserveNullAndEmptyArrays)
                ]
            ]
        }

        switch method {
        case .left:
            return [lookup]
        case .inner:
            return [lookup, unwind(preserveNullAndEmptyArrays: false)]
        case .outer:
            return [lookup, unwind(preserveNullAndEmptyArrays: true)]
        default:
            throw Error.unsupportedJoinMethod
        }
    }
}

extension DatabaseQuery.Join.Method: Equatable {

    public enum Mongo: Equatable {
        case outer
    }

    public static var outer: DatabaseQuery.Join.Method {
        return .custom(Mongo.outer)
    }

    private var isOuter: Bool {
        switch self {
        case .custom(let value as Mongo):
            switch value {
            case .outer:
                return true
            }
        default:
            return false
        }
    }

    public static func == (lhs: DatabaseQuery.Join.Method, rhs: DatabaseQuery.Join.Method) -> Bool {
        switch (lhs, rhs) {
        case (.left, .left),
             (.inner, .inner):
            return true
        case (.custom(let lhs as Mongo), .custom(let rhs as Mongo)):
            return lhs == rhs
        default:
            return false
        }
    }
}

extension Array where Element == DatabaseQuery.Join {

    func mongoLookup() throws -> [BSONDocument] {
        return try self.flatMap { join -> [BSONDocument] in
            try join.mongoLookup()
        }
    }
}

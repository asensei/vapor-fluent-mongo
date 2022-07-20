//
//  DatabaseQueryField+Mongo.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 21/05/2020.
//  Copyright © 2020 Asensei Inc. All rights reserved.
//

import Foundation
import FluentKit

extension DatabaseQuery.Field {

    func mongoDistinct(mainSchema: String) throws -> (key: String, value: String) {
        return try (
            key: self.mongoKeys(namespace: true).joined(separator: ":"), // It is not possible to use dots when specifying an id field for $group
            value: "$" + self.mongoKeyPath(namespace: self.schema != mainSchema)
        )
    }

    func mongoProject(mainSchema: String) throws -> (key: String, value: Bool) {
        return try (
            key: self.mongoKeyPath(namespace: self.schema != mainSchema),
            value: true
        )
    }
}

extension Array where Element == DatabaseQuery.Field {

    func mongoDistinct(mainSchema: String) throws -> [BSONDocument] {

        var id = try self.reduce(into: BSONDocument()) { document, field in
            guard field.schema == nil || field.schema == mainSchema else {
                return
            }
            let result = try field.mongoDistinct(mainSchema: mainSchema)
            document[result.key] = .string(result.value)
        }

        if id.isEmpty {
            id[mainSchema + ":_id"] = "$_id"
        }

        let group: BSONDocument = [
            "_id": .document(id),
            "doc": ["$first": "$$ROOT"]
        ]

        return [
            ["$group": .document(group)],
            ["$replaceRoot": ["newRoot": "$doc"]]
        ]
    }

    func mongoProject(mainSchema: String) throws -> [BSONDocument] {

        var projection = try self.reduce(into: BSONDocument()) { document, field in
            let result = try field.mongoProject(mainSchema: mainSchema)
            document[result.key] = .bool(result.value)
        }

        guard !projection.isEmpty else {
            return []
        }

        if !projection.hasKey("_id") {
            projection["_id"] = false
        }

        return [["$project": .document(projection)]]
    }
}

extension DatabaseQuery.Field {

    func mongoKeyPath(namespace: Bool = false) throws -> String {
        return try self.mongoKeys(namespace: namespace).dotNotation
    }

    func mongoKeys(namespace: Bool = false) throws -> [String] {
        switch self {
        case .path(let value, let schema) where namespace:
            return ([schema] + value.mongoKeys)
        case .path(let value, _):
            return value.mongoKeys
        case .extendedPath(let value, let schema, .none) where namespace:
            return ([schema] + value.mongoKeys)
        case .extendedPath(let value, _, .none):
            return value.mongoKeys
        case .extendedPath(_, _, .some):
            throw Error.unsupportedField
        case .custom(let value as [String]):
            return value
        case .custom(let value as String):
            return [value]
        case .custom:
            throw Error.unsupportedField
        }
    }

    var schema: String? {
        switch self {
        case .path(_, let schema):
            return schema
        default:
            return nil
        }
    }
}

extension FieldKey {

    var mongoKey: String {
        switch self {
        case .id:
            return "_id"
        case .string(let value):
            return value
        case .aggregate:
            return "aggregate_result"
        case .prefix(let prefix, let key):
            return prefix.mongoKey + key.mongoKey
        }
    }
}

extension Array where Element == FieldKey {

    var mongoKeys: [String] {
        return self.map { $0.mongoKey }
    }
}

extension Array where Element == String {

    var dotNotation: String {
        return self.joined(separator: ".")
    }
}

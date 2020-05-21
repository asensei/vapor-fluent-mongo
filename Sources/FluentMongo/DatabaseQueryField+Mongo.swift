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

    func mongoKeyPath(namespace: Bool = false) throws -> String {
        switch self {
        case .path(let value, let schema) where namespace:
            return ([schema] + value.mongoKeys).dotNotation
        case .path(let value, _):
            return value.mongoKeys.dotNotation
        case .custom(let value as String):
            return value
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
            return "aggregate"
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

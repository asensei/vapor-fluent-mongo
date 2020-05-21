//
//  DatabaseQueryValue+Mongo.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 21/05/2020.
//  Copyright © 2020 Asensei Inc. All rights reserved.
//

import Foundation
import FluentKit

extension DatabaseQuery.Value {

    func mongoValue(encoder: BSONEncoder) throws -> BSON {
        switch self {
        case .bind(let encodable):
            return try encoder.encode(encodable)
        case .null:
            return .null
        case .array(let values):
            return try .array(values.map { try $0.mongoValue(encoder: encoder) })
        case .dictionary(let dict):
            return try .document(dict.reduce(into: Document()) { result, element in
                result[element.key.mongoKey] = try element.value.mongoValue(encoder: encoder)
            })
        case .enumCase(let value):
            return .string(value)
        case .custom(let value as BSON):
            return value
        case .custom:
            throw Error.unsupportedValue
        case .default:
            throw Error.unsupportedValue
        }
    }
}

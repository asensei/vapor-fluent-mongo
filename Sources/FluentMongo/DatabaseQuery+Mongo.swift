//
//  DatabaseQuery+Mongo.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 19/05/2020.
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
            fatalError() // not supported
        case .default:
            fatalError()
        }
    }
}

extension DatabaseQuery.Filter.Method {

    var mongoOperator: String {
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
            fatalError()
        case .custom(let value as String):
            return value
        default:
            #warning("TODO: implement this")
            fatalError() // not supported
        }
    }
}

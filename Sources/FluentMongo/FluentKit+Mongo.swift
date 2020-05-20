//
//  FluentKit+Mongo.swift
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
            throw Error.unsupportedValue
        case .default:
            throw Error.unsupportedValue
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

extension DatabaseQuery.Join.Method: Equatable {

    public enum Mongo {
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

    public static func ==(lhs: DatabaseQuery.Join.Method, rhs: DatabaseQuery.Join.Method) -> Bool {
        switch (lhs, rhs) {
        case (.left, .left):
            return true
        case (.inner, .inner):
            return true
        case (.outer, .outer):
            return true
        default:
            return false
        }
    }
}

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

extension DatabaseSchema.DataType {

    var mongoType: String? {
        switch self {
        case .bool:
            return "bool"
        case .json:
            return "object"
        case .int8, .int16, .int32, .uint8, .uint16, .uint32:
            return "int"
        case .int64, .uint64:
            return "long"
        case .enum(let value):
            #warning("TODO: https://github.com/vapor/fluent-kit/pull/90")
            return "string"
        case .string:
            return "string"
        case .time, .date, .datetime:
            return "date"
        case .float, .double:
            return "double"
        case .data:
            return "binData"
        case .uuid:
            return "binData"
        case .custom(_):
            return nil
        case .array(_):
            return nil
        }
    }
}

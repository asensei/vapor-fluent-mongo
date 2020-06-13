//
//  DatabaseSchemaFieldDefinition+Mongo.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 19/05/2020.
//  Copyright © 2020 Asensei Inc. All rights reserved.
//

import Foundation
import FluentKit

extension DatabaseSchema.FieldDefinition {

    func mongoValidatorProperty() throws -> (key: String, value: BSONDocument, isRequired: Bool)? {
        switch self {
        case .definition(let name, let dataType, let constraints):
            guard let mongoType = dataType.mongoType(required: constraints.isRequired) else {
                return nil
            }

            return try (
                key: name.mongoKey(),
                value: mongoType,
                isRequired: constraints.isRequired
            )

        case .custom(let value as (key: String, value: BSONDocument, isRequired: Bool)):
            return value
        case .custom:
            return nil
        }
    }
}

extension Array where Element == DatabaseSchema.FieldDefinition {

    func mongoValidator() throws -> BSONDocument {

        let properties = try self.compactMap { try $0.mongoValidatorProperty() }
        let requiredProperties = properties.filter { $0.isRequired }

        var document: BSONDocument = ["$jsonSchema": .document(["bsonType": "object"])]

        if !requiredProperties.isEmpty {
            document["$jsonSchema", "required"] = .array(requiredProperties.map { .string($0.0) })
        }

        if !properties.isEmpty {
            document["$jsonSchema", "properties"] = .document(properties.reduce(into: BSONDocument(), { document, property in
                document[property.key] = .document(property.value)
            }))
        }

        return document
    }
}

extension DatabaseSchema.FieldName {

    func mongoKey() throws -> String {
        switch self {
        case .key(let value):
            return value.mongoKey
        case .custom(let value as String):
            return value
        case .custom:
            throw Error.unsupportedFieldName
        }
    }
}

extension DatabaseSchema.FieldUpdate {

    func mongoValidatorProperty() throws -> (key: String, value: BSONDocument)? {
        switch self {
        case .dataType(let name, let dataType):
            guard let mongoType = dataType.mongoType(required: false) else {
                return nil
            }

            return try (
                key: name.mongoKey(),
                value: mongoType
            )

        case .custom(let value as (key: String, value: BSONDocument)):
            return value
        case .custom:
            return nil
        }
    }
}

extension Array where Element == DatabaseSchema.FieldUpdate {

    func mongoValidator(updating validator: BSONDocument? = nil) throws -> BSONDocument {

        let properties = try self.compactMap { try $0.mongoValidatorProperty() }

        guard var document = validator else {
            return [
                "$jsonSchema": .document([
                    "bsonType": "object",
                    "properties": .document(properties.reduce(into: BSONDocument(), { document, property in
                        document[property.key] = .document(property.value)
                    }))
                ])
            ]
        }

        let previousProperties = document["$jsonSchema", "properties"]?.documentValue ?? [:]

        document["$jsonSchema", "properties"] = .document(properties.reduce(into: previousProperties, { result, property in
            result[property.key] = .document(property.value)
        }))

        return document
    }
}

extension DatabaseSchema.FieldConstraint {

    var isRequired: Bool {
        switch self {
        case .required:
            return true
        default:
            return false
        }
    }
}

extension Array where Element == DatabaseSchema.FieldConstraint {

    var isRequired: Bool {
        return self.contains { $0.isRequired }
    }
}

extension DatabaseSchema.Constraint {

    func mongoIndex() throws -> IndexModel? {
        switch self {
        case .constraint(let alg, let name):
            switch alg {
            case .unique(let fields):
                return .init(
                    keys: try fields.reduce(into: BSONDocument(), { document, field in
                        try document[field.mongoKey()] = .init(DatabaseQuery.Sort.Direction.ascending.mongoSortDirection())
                    }),
                    options: .init(name: name, unique: true)
                )
            default:
                return nil
            }
        default:
            return nil
        }
    }
}

extension Array where Element == DatabaseSchema.Constraint {

    func mongoIndexes() throws -> [IndexModel] {
        return try self.compactMap { try $0.mongoIndex() }
    }
}

extension DatabaseSchema.DataType {

    func mongoType(required: Bool) -> BSONDocument? {

        guard let key = self.mongoTypeKey, var alias = self.mongoTypeAlias, !alias.isEmpty else {
            return nil
        }

        if !required {
            alias += ["null"]
        }

        switch alias.count {
        case 1:
            return [key: .string(alias[0])]
        default:
            return [key: .array(alias.map { .string($0) })]
        }
    }

    var mongoTypeKey: String? {
        switch self {
        case .bool,
             .custom(is Bool.Type),
             .dictionary,
             .array,
             .int8, .int16, .int32, .uint8, .uint16, .uint32,
             .custom(is Int8.Type), .custom(is Int16.Type), .custom(is Int32.Type),
             .custom(is UInt8.Type), .custom(is UInt16.Type), .custom(is UInt32.Type),
             .int64, .uint64, .custom(is Int64.Type), .custom(is UInt64.Type),
             .string, .custom(is String.Type),
             .time, .date, .datetime, .custom(is Date.Type),
             .float, .double, .custom(is Float.Type), .custom(is Double.Type),
             .data, .custom(is Data.Type),
             .uuid, .custom(is UUID.Type):
            return "bsonType"
        case .enum:
            return "enum"
        case .custom:
            return nil
        }
    }

    var mongoTypeAlias: [String]? {
        switch self {
        case .bool, .custom(is Bool.Type):
            return ["bool"]
        case .dictionary:
            return ["object"]
        case .array:
            return ["array"]
        case .int8, .int16, .int32, .uint8, .uint16, .uint32,
             .custom(is Int8.Type), .custom(is Int16.Type), .custom(is Int32.Type),
             .custom(is UInt8.Type), .custom(is UInt16.Type), .custom(is UInt32.Type):
            return ["int"]
        case .int64, .uint64, .custom(is Int64.Type), .custom(is UInt64.Type):
            return ["long"]
        case .string, .custom(is String.Type):
            return ["string"]
        case .time, .date, .datetime, .custom(is Date.Type):
            return ["date"]
        case .float, .double, .custom(is Float.Type), .custom(is Double.Type):
            return ["double"]
        case .data, .custom(is Data.Type):
            return ["binData"]
        case .uuid, .custom(is UUID.Type):
            return ["binData"]
        case .enum(let value):
            return value.cases
        case .custom:
            return nil
        }
    }
}

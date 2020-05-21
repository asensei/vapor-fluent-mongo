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

    func mongoValidatorProperty() throws -> (key: String, value: Document, isRequired: Bool)? {
        switch self {
        case .definition(let name, let dataType, let constraints):
            guard let mongoType = dataType.mongoType else {
                return nil
            }

            return try (
                key: name.mongoKey(),
                value: mongoType,
                isRequired: constraints.isRequired
            )

        case .custom(let value as (key: String, value: Document, isRequired: Bool)):
            return value
        case .custom:
            return nil
        }
    }
}

extension Array where Element == DatabaseSchema.FieldDefinition {

    func mongoValidator() throws -> Document {

        let properties = try self.compactMap { try $0.mongoValidatorProperty() }
        let requiredProperties = properties.filter { $0.isRequired }

        var document: Document = ["$jsonSchema": .document(["bsonType": "object"])]

        if !requiredProperties.isEmpty {
            document["$jsonSchema", "required"] = .array(requiredProperties.map { .string($0.0) })
        }

        if !properties.isEmpty {
            document["$jsonSchema", "properties"] = .document(properties.reduce(into: Document(), { document, property in
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

    func mongoValidatorProperty() throws -> (key: String, value: Document)? {
        switch self {
        case .dataType(let name, let dataType):
            guard let mongoType = dataType.mongoType else {
                return nil
            }

            return try (
                key: name.mongoKey(),
                value: mongoType
            )

        case .custom(let value as (key: String, value: Document)):
            return value
        case .custom:
            return nil
        }
    }
}

extension Array where Element == DatabaseSchema.FieldUpdate {

    func mongoValidator(updating validator: Document? = nil) throws -> Document {

        let properties = try self.compactMap { try $0.mongoValidatorProperty() }

        guard var document = validator else {
            return [
                "$jsonSchema": .document([
                    "bsonType": "object",
                    "properties": .document(properties.reduce(into: Document(), { document, property in
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
        case .unique(let fields):
            return .init(
                keys: try fields.reduce(into: Document(), { document, field in
                    try document[field.mongoKey()] = .init(DatabaseQuery.Sort.Direction.ascending.mongoSortDirection())
                }),
                options: .init(unique: true)
            )
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

    var mongoType: Document? {
        switch self {
        case .bool, .custom(is Bool.Type):
            return ["bsonType": "bool"]
        case .json:
            return ["bsonType": "object"]
        case .array:
            return ["bsonType": "array"]
        case .int8, .int16, .int32, .uint8, .uint16, .uint32,
             .custom(is Int8.Type), .custom(is Int16.Type), .custom(is Int32.Type),
             .custom(is UInt8.Type), .custom(is UInt16.Type), .custom(is UInt32.Type):
            return ["bsonType": "int"]
        case .int64, .uint64, .custom(is Int64.Type), .custom(is UInt64.Type):
            return ["bsonType": "long"]
        case .string, .custom(is String.Type):
            return ["bsonType": "string"]
        case .time, .date, .datetime, .custom(is Date.Type):
            return ["bsonType": "date"]
        case .float, .double, .custom(is Float.Type), .custom(is Double.Type):
            return ["bsonType": "double"]
        case .data, .custom(is Data.Type):
            return ["bsonType": "binData"]
        case .uuid, .custom(is UUID.Type):
            return ["bsonType": "binData"]
        case .enum(let value):
            return ["enum": .array(value.cases.map { .string($0) })]
        case .custom:
            return nil
        }
    }
}

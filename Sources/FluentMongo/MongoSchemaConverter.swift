//
//  MongoSchemaConverter.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 28/10/2019.
//  Copyright © 2019 Asensei Inc. All rights reserved.
//

import Foundation
import FluentKit
import MongoSwift

struct MongoSchemaConverter {

    public init(_ schema: DatabaseSchema, customPropertySchemaGenerator: MongoCustomPropertySchemaGenerator? = nil) {
        self.schema = schema
        self.customPropertySchemaGenerator = customPropertySchemaGenerator
    }

    private let schema: DatabaseSchema

    private let customPropertySchemaGenerator: MongoCustomPropertySchemaGenerator?

    public func convert(_ database: MongoSwift.MongoDatabase, on eventLoop: EventLoop) -> EventLoopFuture<Void> {
        switch self.schema.action {
        case .create:
            return self.create(database, on: eventLoop)
        case .update:
            return self.update(database, on: eventLoop)
        case .delete:
            return self.delete(database, on: eventLoop)
        }
    }
}

extension MongoSchemaConverter {

    private func create(_ database: MongoSwift.MongoDatabase, on eventLoop: EventLoop) -> EventLoopFuture<Void> {

        var jsonSchema: Document = ["bsonType": "object"]

        if let required = self.required(fields: self.schema.createFields) {
            jsonSchema.required = required
        }

        if let properties = self.properties(fields: self.schema.createFields) {
            jsonSchema.properties = properties
        }

        let options = CreateCollectionOptions(validator: nil
            // TODO: Disabled until test pass.
            // ["$jsonSchema": .document(jsonSchema)]
        )

        return database.createCollection(self.schema.schema, options: options).transform(to: Void())
    }

    private func update(_ database: MongoSwift.MongoDatabase, on eventLoop: EventLoop) -> EventLoopFuture<Void> {
        #warning("TODO: Ask Tanner. Nothing seem to be calling update. It's not clear how is supposed to work.")
        return eventLoop.makeSucceededFuture(Void())
    }

    private func delete(_ database: MongoSwift.MongoDatabase, on eventLoop: EventLoop) -> EventLoopFuture<Void> {
        return database.collection(self.schema.schema).drop()
    }
}

extension MongoSchemaConverter {

    private func required(fields: [DatabaseSchema.FieldDefinition]) -> BSON? {

        let result: [String] = fields.compactMap { field in

            guard
                case .definition(let fieldName, _, let constraints) = field,
                constraints.contains(where: {
                    guard case DatabaseSchema.FieldConstraint.required = $0 else {
                        return false
                    }
                    return true
                }) else {
                return nil
            }

            guard case .key(let key) = fieldName else {
                return nil
            }

            return key.mongoKey
        }

        return result.isEmpty ? nil : .array(result.map { .string($0) })
    }

    private func properties(fields: [DatabaseSchema.FieldDefinition]) -> BSON? {

        var properties: [String: BSON] = [:]

        for field in fields {
            switch field {
            case .definition(let fieldName, let dataType, _):

                guard case .key(let key) = fieldName, let bsonType = dataType.mongoType else {
                    continue
                }

                var document: Document = ["bsonType": .string(bsonType)]

                if case let DatabaseSchema.DataType.enum(value) = dataType {
                    document.enum = .array(value.cases.map { .string($0) })
                }

                properties[key.mongoKey] = .document(document)

            case .custom(let value):

                guard let customProperty = self.customPropertySchemaGenerator?.propertySchema(for: value) else {

                    fatalError("Unhandled custom property type in schema")
                    continue
                }

                properties[customProperty.key.mongoKey] = .document(customProperty.schema)
            }
        }

        return properties.isEmpty ? nil : {
            var document = Document()

            for property in properties {
                document[property.key] = property.value
            }

            return .document(document)
        }()
    }
}

public protocol MongoCustomPropertySchemaGenerator {

    func propertySchema(for customField: Any) -> MongoCustomPropertySchema?
}

public struct MongoCustomPropertySchema {

    /// The key for the respective property.
    public let key: FieldKey

    /// A `Schema Document` for the respective property. https://docs.mongodb.com/stitch/mongodb/document-schemas/
    public let schema: Document
}

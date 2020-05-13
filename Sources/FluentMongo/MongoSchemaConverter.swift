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
/*
public struct MongoSchemaConverter {

    public init(_ schema: DatabaseSchema) {
        self.schema = schema
    }

    private let schema: DatabaseSchema

    public func convert(_ database: MongoDatabase) throws -> [DatabaseRow] {
        switch self.schema.action {
        case .create:
            try self.create(database)
        case .update:
            try self.update(database)
        case .delete:
            try self.delete(database)
        }

        return []
    }
}

extension MongoSchemaConverter {

    private func create(_ database: MongoDatabase) throws {

        var jsonSchema: Document = ["bsonType": "object"]

        if let required = self.required() {
            jsonSchema["required"] = required
        }

        if let properties = self.properties() {
            jsonSchema["properties"] = properties
        }

        let options = CreateCollectionOptions(validator: [
            "$jsonSchema": jsonSchema
        ])

        _ = try database.createCollection(self.schema.schema, options: options)

//        let system = database.collection("system.js")
//        let r = try system.insertOne([
//            "_id": "getNextSequence",
//            "value":
//            """
//            function getNextSequence(name) {
//               var ret = db.counters.findAndModify(
//                      {
//                        query: { _id: name },
//                        update: { $inc: { seq: 1 } },
//                        new: true
//                      }
//               );
//
//               return ret.seq;
//            }
//            """
//        ])
//        print(r)
    }

    private func update(_ database: MongoDatabase) throws {
        #warning("TODO: Ask Tanner. Nothing seem to be calling update. It's not clear how is supposed to work.")
    }

    private func delete(_ database: MongoDatabase) throws {
        #warning("TODO: Remove the validation rules or the whole collection?")
    }
}

extension MongoSchemaConverter {

    private func required() -> [String]? {
        let result: [String] = self.schema.createFields.compactMap { field in
            guard case .definition(let fieldName, _, _) = field else {
                return nil
            }
            guard case .string(let name) = fieldName else {
                return nil
            }

            return name
        }

        return result.isEmpty ? nil : result
    }

    private func properties() -> Document? {

        var document = Document()

        for field in self.schema.createFields {
            switch field {
            case .definition(let fieldName, let dataType, _):

                guard case .string(let name) = fieldName, let bsonType = self.bsonType(dataType) else {
                    continue
                }

                document[name] = ["bsonType": bsonType] as Document

            case .custom(let value):
                #warning("TODO: implement this")
                continue
            }
        }
        
        return document.isEmpty ? nil : document
    }

    private func bsonType(_ data: DatabaseSchema.DataType) -> String? {
        switch data {
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
        }
    }
}
*/
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

    public init(_ schema: DatabaseSchema) {
        self.schema = schema
    }

    private let schema: DatabaseSchema

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
        return database.createCollection(self.schema.schema).transform(to: Void())
    }

    private func update(_ database: MongoSwift.MongoDatabase, on eventLoop: EventLoop) -> EventLoopFuture<Void> {
        #warning("TODO: Ask Tanner. Nothing seem to be calling update. It's not clear how is supposed to work.")
        return eventLoop.makeSucceededFuture(Void())
    }

    private func delete(_ database: MongoSwift.MongoDatabase, on eventLoop: EventLoop) -> EventLoopFuture<Void> {
        return database.collection(self.schema.schema).drop()
    }
}

/* TODO: implement schema constraints
extension MongoSchemaConverter {

        private func create(_ database: MongoSwift.MongoDatabase, on eventLoop: EventLoop) -> EventLoopFuture<Void> {

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
}
*/

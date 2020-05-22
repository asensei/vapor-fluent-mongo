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

    public func convert(_ database: MongoSwift.MongoDatabase, session: ClientSession? = nil, on eventLoop: EventLoop) -> EventLoopFuture<Void> {
        switch self.schema.action {
        case .create:
            return self.create(database, session, on: eventLoop)
        case .update:
            return self.update(database, session, on: eventLoop)
        case .delete:
            return self.delete(database, session, on: eventLoop)
        }
    }
}

extension MongoSchemaConverter {

    private func create(_ database: MongoSwift.MongoDatabase, _ session: ClientSession?, on eventLoop: EventLoop) -> EventLoopFuture<Void> {
        do {
            // TODO: re-enable once https://github.com/vapor/fluent-kit/issues/282 is fixed
            let options = try CreateCollectionOptions(validator: nil/*self.schema.createFields.mongoValidator()*/)

            return database.createCollection(self.schema.schema, options: options, session: session).flatMap { collection in
                do {
                    let indexModels = try self.schema.constraints.mongoIndexes()
                    guard !indexModels.isEmpty else {
                        return eventLoop.makeSucceededFuture(Void())
                    }
                    return collection.createIndexes(indexModels, session: session).transform(to: Void())
                } catch {
                    return eventLoop.makeFailedFuture(error)
                }
            }
        } catch {
            return eventLoop.makeFailedFuture(error)
        }
    }

    private func update(_ database: MongoSwift.MongoDatabase, _ session: ClientSession?, on eventLoop: EventLoop) -> EventLoopFuture<Void> {

        return database
            .listCollections(["name": .string(self.schema.schema)], session: session)
            .flatMap { $0.toArray() }
            .flatMap {
                do {
                    guard let collectionSpecification = $0.first else {
                        throw Error.collectionNotFound(self.schema.schema)
                    }

                    let validator = try self.schema.updateFields.mongoValidator(updating: collectionSpecification.options?.validator)

                    return database.runCommand([
                        "collMod": .string(self.schema.schema),
                        "validator": .document(validator),
                        "validationLevel": "moderate"
                    ], session: session).transform(to: Void())
                } catch {
                    return eventLoop.makeFailedFuture(error)
                }
            }
    }

    private func delete(_ database: MongoSwift.MongoDatabase, _ session: ClientSession?, on eventLoop: EventLoop) -> EventLoopFuture<Void> {
        return database.collection(self.schema.schema).drop(session: session)
    }
}

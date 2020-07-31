//
//  MongoDatabaseOutput.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 15/05/2020.
//  Copyright © 2020 Asensei Inc. All rights reserved.
//

import Foundation
import FluentKit
import MongoSwift

extension BSONDocument {
    func databaseOutput(fields: [DatabaseQuery.Field], using decoder: BSONDecoder) -> DatabaseOutput {
        MongoDatabaseOutput(document: self, decoder: decoder, schema: nil, fields: fields)
    }
}

private struct MongoDatabaseOutput: DatabaseOutput {

    let document: BSONDocument
    let decoder: BSONDecoder
    let schema: String?
    let fields: [DatabaseQuery.Field]

    var description: String {
        self.document.description
    }

    func schema(_ schema: String) -> DatabaseOutput {
        return MongoDatabaseOutput(document: self.document, decoder: self.decoder, schema: schema, fields: self.fields)
    }

    func contains(_ key: FieldKey) -> Bool {
        return self.namespace.hasKey(key.mongoKey)
    }

    func decodeNil(_ key: FieldKey) throws -> Bool {

        // https://github.com/mongodb/mongo-swift-driver/issues/516#issuecomment-666863404
        guard let value = self.namespace[key.mongoKey] else {
            return true
        }

        switch value {
        case .undefined, .null:
            return true
        default:
            return false
        }
    }

    func decode<T>(_ key: FieldKey, as type: T.Type) throws -> T where T: Decodable {
        return try self.decoder.decode(type, from: self.namespace, forKey: key.mongoKey)
    }

    private var namespace: BSONDocument {
        guard let schema = self.schema else {
            return self.document
        }

        return self.document[schema]?.documentValue ?? self.document
    }
}

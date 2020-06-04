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

extension Document {
    func databaseOutput(fields: [DatabaseQuery.Field], using decoder: BSONDecoder) -> DatabaseOutput {
        MongoDatabaseOutput(document: self, decoder: decoder, schema: nil, fields: fields)
    }
}

private struct MongoDatabaseOutput: DatabaseOutput {

    let document: Document
    let decoder: BSONDecoder
    let schema: String?
    let fields: [DatabaseQuery.Field]

    var description: String {
        self.document.description
    }

    func schema(_ schema: String) -> DatabaseOutput {

        let document: Document

        switch (self.schema, schema) {
        case (.some(let lhs), let rhs):
            if lhs == rhs {
                document = self.document
            } else {
                document = self.document[schema]?.documentValue ?? Document()
            }
        case (.none, _):
            document = self.document
        }

        return MongoDatabaseOutput(document: document, decoder: self.decoder, schema: schema, fields: self.fields)
    }

    func contains(_ key: FieldKey) -> Bool {
        guard !self.document.hasKey(key.mongoKey) else {
            return true
        }

        return self.fields.contains { field in
            switch field {
            case .path(let fieldKeys, let schema) where schema == self.schema:
                return fieldKeys.mongoKeys.last == key.mongoKey
            default:
                return false
            }
        }
    }

    func decodeNil(_ key: FieldKey) throws -> Bool {
        switch self.document[key.mongoKey] {
        case .undefined, .null, .none:
            return true
        default:
            return false
        }
    }

    func decode<T>(_ key: FieldKey, as type: T.Type) throws -> T where T: Decodable {
        guard self.document.hasKey(key.mongoKey) else {
            switch T.self {
            case is ExpressibleByNilLiteral.Type:
                guard let result = (nil as Any?) as? T else {
                    throw Error.invalidResult
                }

                return result
            default:
                throw Error.unsupportedField
            }
        }

        return try self.decoder.decode(type, from: self.document, forKey: key.mongoKey)
    }
}

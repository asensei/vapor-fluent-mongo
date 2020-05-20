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
    func databaseOutput(using decoder: BSONDecoder) -> DatabaseOutput {
        MongoDatabaseOutput(document: self, decoder: decoder, schema: nil)
    }
}

private struct MongoDatabaseOutput: DatabaseOutput {
    let document: Document
    let decoder: BSONDecoder
    let schema: String?

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

        return MongoDatabaseOutput(document: document, decoder: self.decoder, schema: schema)
    }

    func contains(_ path: [FieldKey]) -> Bool {
        return self.document[path.mongoKeys] != nil
    }

    func decode<T: Decodable>(_ path: [FieldKey], as type: T.Type) throws -> T {

        switch path.count {
        case 1:
            return try self.decoder.decode(type, from: self.document, forKey: path.mongoKeys.dotNotation)
        default:
            let value = self.document[path.mongoKeys] ?? .null
            let document: Document = ["value": value]

            return try self.decoder.decode(type, from: document, forKey: "value")
        }
    }
}

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
        MongoDatabaseOutput(document: self.document, decoder: self.decoder, schema: schema)
    }

    func contains(_ path: [FieldKey]) -> Bool {
        return self.document[dynamicMember: path.dotNotationKey] != nil
    }

    func decode<T: Decodable>(_ path: [FieldKey], as type: T.Type) throws -> T {

        let value = self.document[dynamicMember: path.dotNotationKey] ?? .null
        let document: Document = ["value": value]

        return try self.decoder.decode(type, from: document, forKey: "value")
    }
}

extension Array where Element == FieldKey {

    fileprivate var dotNotationKey: String {
        return self.map { key in
            switch key {
            case .id:
                return "_id"
            case .string(let value):
                return value
            case .aggregate:
                return "aggregate"
            }
        }.joined(separator: ".")
    }
}

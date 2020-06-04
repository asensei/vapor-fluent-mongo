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

    func contains(_ key: FieldKey) -> Bool {
        return self.document[key.mongoKey] != nil
    }

    func decodeNil(_ key: FieldKey) throws -> Bool {
        return self.document[key.mongoKey] == .null
    }

    func decode<T>(_ key: FieldKey, as type: T.Type) throws -> T where T: Decodable {
        return try self.decoder.decode(type, from: self.document, forKey: key.mongoKey)
    }
}

private struct __MongoDatabaseOutput: DatabaseOutput {

    let document: Document
    let decoder: BSONDecoder
    let schema: String?

    var description: String {
        self.document.description
    }

    func schema(_ schema: String) -> DatabaseOutput {
        return MongoDatabaseOutput(document: self.document, decoder: self.decoder, schema: schema)
    }

    func contains(_ key: FieldKey) -> Bool {
        return true
    }

    func decodeNil(_ key: FieldKey) throws -> Bool {
        switch self.bson(key) {
        case .undefined, .null, .none:
            return true
        default:
            return false
        }
    }

    func decode<T>(_ key: FieldKey, as type: T.Type) throws -> T where T: Decodable {

        let document = self.bson(key)?.documentValue ?? [:]

//        guard document[key.mongoKey] != nil/*, !(type is ExpressibleByNilLiteral)*/ else {
////            let anyNil: Any? = nil
////
////            return anyNil as! T
//            switch T.self {
//            case let t as ExpressibleByNilLiteral.Type:
//                return t.init(nilLiteral: ()) as! T
//            default:
//                fatalError()
//            }
//        }

        return try self.decoder.decode(type, from: document, forKey: key.mongoKey)
    }

    private func bson(_ key: FieldKey) -> BSON? {
        guard let schema = self.schema else {
            return self.document[key.mongoKey]
        }

        return self.document[schema]?.documentValue?[key.mongoKey]
    }
}

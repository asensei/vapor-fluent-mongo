//
//  DatabaseQuery+Additions.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 25/10/2019.
//  Copyright © 2019 Asensei Inc. All rights reserved.
//

import Foundation
import FluentKit
/*
extension DatabaseQuery.Schema {

    func schema() throws -> (name: String, alias: String?) {
        switch self {
        case .schema(let name, let alias):
            return (name: name, alias: alias)
        default:
            throw Error.invalidSchemaType
        }
    }

    func custom() throws -> Any {
        switch self {
        case .custom(let value):
            return value
        default:
            throw Error.invalidSchemaType
        }
    }

    enum Error: Swift.Error, LocalizedError, CustomStringConvertible {
        case invalidSchemaType

        public var description: String {
            switch self {
            case .invalidSchemaType:
                return "invalid schema type"
            }
        }

        public var errorDescription: String? {
            return self.description
        }
    }
}

extension DatabaseQuery.Field {

    func aggregate() throws -> Aggregate {
        switch self {
        case .aggregate(let aggregate):
            return aggregate
        default:
            throw Error.invalidFieldType
        }
    }

    func field() throws -> QueryField {
        switch self {
        case .field(let path, let schema, let alias):
            return .init(path: path, schema: schema, alias: alias)
        default:
            throw Error.invalidFieldType
        }
    }

    func custom() throws -> Any {
        switch self {
        case .custom(let value):
            return value
        default:
            throw Error.invalidFieldType
        }
    }

    struct QueryField {
        let path: [String]
        let schema: String?
        let alias: String?

        var pathWithNamespace: [String] {
            guard let schema = self.schema else {
                return self.path
            }

            return [schema] + self.path
        }
    }

    enum Error: Swift.Error, LocalizedError, CustomStringConvertible {
        case invalidFieldType

        public var description: String {
            switch self {
            case .invalidFieldType:
                return "invalid field type"
            }
        }

        public var errorDescription: String? {
            return self.description
        }
    }
}

extension DatabaseQuery.Join {

    func join() throws -> (schema: DatabaseQuery.Schema, foreign: DatabaseQuery.Field, local: DatabaseQuery.Field, method: DatabaseQuery.Join.Method) {
        switch self {
        case .join(let schema, let foreign, let local, let method):
            return (schema: schema, foreign: foreign, local: local, method: method)
        default:
            throw Error.invalidJoinType
        }
    }

    func custom() throws -> Any {
        switch self {
        case .custom(let value):
            return value
        default:
            throw Error.invalidJoinType
        }
    }

    enum Error: Swift.Error, LocalizedError, CustomStringConvertible {
        case invalidJoinType

        public var description: String {
            switch self {
            case .invalidJoinType:
                return "invalid join type"
            }
        }

        public var errorDescription: String? {
            return self.description
        }
    }
}

extension DatabaseQuery.Join.Method {

    var isOuter: Bool {
        switch self {
        case .outer:
            return true
        default:
            return false
        }
    }
}
*/
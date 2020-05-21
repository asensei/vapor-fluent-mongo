//
//  DatabaseQueryJoin+Mongo.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 21/05/2020.
//  Copyright © 2020 Asensei Inc. All rights reserved.
//

import Foundation
import FluentKit

extension DatabaseQuery.Join {

    func mongoLookup() throws -> [Document] {
        switch self {
        case .join(let schema, let alias, let method, let foreign, let local):

            let lookup: Document = [
                "$lookup": [
                    "from": .string(schema),
                    "localField": .string(try local.mongoKeyPath()),
                    "foreignField": .string(try foreign.mongoKeyPath()),
                    "as": .string(alias ?? schema)
                ]
            ]

            func unwind(preserveNullAndEmptyArrays: Bool) -> Document {
                return [
                    "$unwind": [
                        "path": .string("$" + (alias ?? schema)),
                        "preserveNullAndEmptyArrays": .bool(preserveNullAndEmptyArrays)
                    ]
                ]
            }

            switch method {
            case .left:
                return [lookup]
            case .inner:
                return [lookup, unwind(preserveNullAndEmptyArrays: false)]
            case .outer:
                return [lookup, unwind(preserveNullAndEmptyArrays: true)]
            default:
                throw Error.unsupportedJoinMethod
            }
        case .custom:
            throw Error.unsupportedJoin
        }
    }
}

extension DatabaseQuery.Join.Method: Equatable {

    public enum Mongo {
        case outer
    }

    public static var outer: DatabaseQuery.Join.Method {
        return .custom(Mongo.outer)
    }

    private var isOuter: Bool {
        switch self {
        case .custom(let value as Mongo):
            switch value {
            case .outer:
                return true
            }
        default:
            return false
        }
    }

    public static func ==(lhs: DatabaseQuery.Join.Method, rhs: DatabaseQuery.Join.Method) -> Bool {
        switch (lhs, rhs) {
        case (.left, .left):
            return true
        case (.inner, .inner):
            return true
        case (.outer, .outer):
            return true
        default:
            return false
        }
    }
}

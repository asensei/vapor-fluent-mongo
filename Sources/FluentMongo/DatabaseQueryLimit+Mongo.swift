//
//  DatabaseQueryLimit+Mongo.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 21/05/2020.
//  Copyright © 2020 Asensei Inc. All rights reserved.
//

import Foundation
import FluentKit

extension DatabaseQuery.Limit {

    func mongoLimit() throws -> Int64 {
        switch self {
        case .count(let value):
            return Int64(value)
        case .custom(let value as Int):
            return Int64(value)
        case .custom(let value as Int8):
            return Int64(value)
        case .custom(let value as Int16):
            return Int64(value)
        case .custom(let value as Int32):
            return Int64(value)
        case .custom(let value as Int64):
            return value
        case .custom:
            throw Error.unsupportedLimit
        }
    }
}

extension Array where Element == DatabaseQuery.Limit {

    func mongoLimit() throws -> [BSONDocument] {
        guard let limit = self.first else {
            return []
        }

        return try [["$limit": .int64(limit.mongoLimit())]]
    }
}

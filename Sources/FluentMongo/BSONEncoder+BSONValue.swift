//
//  BSONEncoder+BSONValue.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 11/12/2018.
//  Copyright © 2018 Asensei Inc. All rights reserved.
//

import Foundation
import MongoSwift

extension BSONEncoder {

    public func encodeBSONValue<T: Encodable>(_ value: T) throws -> BSON {
        // if it's already a `BSONValue`, just return it, unless if it is an
        // array. technically `[Any]` is a `BSONValue`, but we can only use this
        // short-circuiting if all the elements are actually BSONValues.
        switch value {
        case let value as BSON where !(value is [Any]):
            return value
        case let value as [BSON]:
            return .array(value)
        default:
            // We can only use BSONEncoder to encode top-level data
            let wrappedData = ["value": value]
            let document: Document = try self.encode(wrappedData)

            return document["value"] ?? .null
        }
    }
}

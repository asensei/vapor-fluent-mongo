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
        switch value {
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

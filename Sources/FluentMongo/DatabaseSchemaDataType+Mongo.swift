//
//  DatabaseSchemaDataType+Mongo.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 19/05/2020.
//  Copyright © 2020 Asensei Inc. All rights reserved.
//

import Foundation
import FluentKit

extension DatabaseSchema.DataType {

    var mongoType: String? {
        switch self {
        case .bool:
            return "bool"
        case .json:
            return "object"
        case .int8, .int16, .int32, .uint8, .uint16, .uint32:
            return "int"
        case .int64, .uint64:
            return "long"
        case .enum(let value):
            #warning("TODO: https://github.com/vapor/fluent-kit/pull/90")
            return "string"
        case .string:
            return "string"
        case .time, .date, .datetime:
            return "date"
        case .float, .double:
            return "double"
        case .data:
            return "binData"
        case .uuid:
            return "binData"
        case .custom(let value as String):
            return value
        case .custom:
            return nil
        case .array(_):
            return "array"
        }
    }
}

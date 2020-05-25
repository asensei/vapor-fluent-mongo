//
//  DatabaseQueryValue+Mongo.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 21/05/2020.
//  Copyright © 2020 Asensei Inc. All rights reserved.
//

import Foundation
import FluentKit

extension DatabaseQuery.Value {

    func mongoValue(encoder: BSONEncoder) throws -> BSON {

        if let updateOperatorValue = self.mongoUpdateArrayOperatorValue() {
            return try Self.dictionary(updateOperatorValue).mongoValue(encoder: encoder)
        }

        switch self {
        case .bind(let encodable):
            return try encoder.encode(encodable)
        case .dictionary(let dict):
            return try .document(dict.reduce(into: Document()) { result, element in
                result[element.key.mongoKey] = try element.value.mongoValue(encoder: encoder)
            })
        case .array(let values):
            return try .array(values.map { try $0.mongoValue(encoder: encoder) })
        case .null:
            return .null
        case .enumCase(let value):
            return .string(value)
        case .`default`:
            throw Error.unsupportedValue
        case .custom(let value as BSON):
            return value
        case .custom:
            throw Error.unsupportedValue
        }
    }
}

extension DatabaseQuery.Value {

    enum MongoUpdateArrayOperator: String, CaseIterable {
        case addToSet
        case push
        case pullAll

        var value: String {
            return "$" + self.rawValue
        }

        var fieldKey: FieldKey {
            return .string(self.value)
        }

        func databaseQueryValue(_ value: [FieldKey: DatabaseQuery.Value]? = nil) -> DatabaseQuery.Value {
            return .dictionary([self.fieldKey: .dictionary(value ?? [:])])
        }
    }

    var mongoUpdateOperator: String {
        for item in MongoUpdateArrayOperator.allCases {
            guard self.mongoUpdateArrayOperatorValue(item) != nil else {
                continue
            }

            return item.value
        }

        return "$set"
    }

    func mongoUpdateArrayOperatorValue(_ identifier: MongoUpdateArrayOperator? = nil) -> [FieldKey: DatabaseQuery.Value]? {

        func find(_ op: MongoUpdateArrayOperator) -> [FieldKey: DatabaseQuery.Value]? {
            switch self {
            case .dictionary(let value):
                switch value[op.fieldKey] {
                case .dictionary(let nested):
                    return nested
                default:
                    return nil
                }
            default:
                return nil
            }
        }

        guard let identifier = identifier else {
            for item in MongoUpdateArrayOperator.allCases {
                guard let value = find(item) else {
                    continue
                }

                return value
            }

            return nil
        }

        return find(identifier)
    }
}

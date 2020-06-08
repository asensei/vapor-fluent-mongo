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

    func mongoValueFilter(encoder: BSONEncoder) throws -> BSON? {
        return try self.mongoValue(ignoreIfNil: false, encoder: encoder)
    }

    func mongoValueInsert(encoder: BSONEncoder) throws -> BSON? {
        return try self.mongoValue(ignoreIfNil: true, encoder: encoder)
    }

    func mongoValueUpdate(encoder: BSONEncoder) throws -> BSON? {

        // Special handling for custom array operators
        for item in MongoUpdateArrayOperator.allCases {
            guard let value = self.mongoUpdateArrayOperatorValue(item) else {
                continue
            }

            guard let bson = try Self.dictionary(value).mongoValue(ignoreIfNil: false, encoder: encoder) else {
                return nil
            }

            return [item.value: bson]
        }

        func mongoValue(_ value: DatabaseQuery.Value, unset: Bool) throws -> BSON? {
            guard unset else {
                return try self.mongoValue(ignoreIfNil: true, encoder: encoder)
            }

            switch value {
            case .bind(let optional as AnyOptionalType) where optional.wrappedValue == nil:
                fallthrough
            case .null:
                return .null // The specified value in the $unset expression (i.e. null) does not impact the operation.
            case .dictionary(let dict):
                  return try .document(dict.reduce(into: Document()) { result, element in
                    result[element.key.mongoKey] = try mongoValue(element.value, unset: unset)
                })
            case .array(let values):
                return try .array(values.compactMap { try mongoValue($0, unset: unset) })
            default:
                return nil
            }
        }

        var document: Document = [:]

        if let set = try mongoValue(self, unset: false)?.documentValue, !set.isEmpty {
            document["$set"] = .document(set)
        }

        if let unset = try mongoValue(self, unset: true)?.documentValue, !unset.isEmpty {
            document["$unset"] = .document(unset)
        }

        return document.isEmpty ? nil : .document(document)
    }

    private func mongoValue(ignoreIfNil: Bool, encoder: BSONEncoder) throws -> BSON? {

        switch self {
        case .bind(let optional as AnyOptionalType) where optional.wrappedValue == nil:
            fallthrough
        case .null:
            return ignoreIfNil ? nil : .null
        case .bind(let encodable):
            return try encoder.encode(encodable)
        case .dictionary(let dict):
            return try .document(dict.reduce(into: Document()) { result, element in
                result[element.key.mongoKey] = try element.value.mongoValue(ignoreIfNil: ignoreIfNil, encoder: encoder)
            })
        case .array(let values):
            return try .array(values.compactMap { try $0.mongoValue(ignoreIfNil: ignoreIfNil, encoder: encoder) })
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

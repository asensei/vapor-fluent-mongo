//
//  Error.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 18/05/2020.
//  Copyright © 2020 Asensei Inc. All rights reserved.
//

import Foundation
import FluentKit
import MongoSwift

public enum Error: Swift.Error, LocalizedError, CustomStringConvertible, DatabaseError {
    case duplicatedKey(String)
    case invalidNestedDocument(String)
    case invalidResult
    case insertManyMismatch(Int, Int)
    case collectionNotFound(String)
    case unsupportedField
    case unsupportedFieldName
    case unsupportedOperator
    case unsupportedValue
    case unsupportedJoin
    case unsupportedJoinMethod
    case unsupportedFilter
    case unsupportedFilterRelation
    case unsupportedQueryAction
    case unsupportedSort
    case unsupportedSortDirection
    case unsupportedOffset
    case unsupportedLimit
    case unsupportedAggregate
    case unsupportedAggregateMethod

    public var description: String {
        switch self {
        case .duplicatedKey(let message):
            return "Duplicated key. \(message)"
        case .invalidNestedDocument(let key):
            return "Invalid nested document for key \(key)"
        case .invalidResult:
            return "Query returned no results"
        case .insertManyMismatch(let count, let expected):
            return "Inserted \(count) documents out of \(expected)"
        case .collectionNotFound(let name):
            return "Collection \"\(name)\" not found"
        case .unsupportedField:
            return "Unsupported field"
        case .unsupportedFieldName:
            return "Unsupported field name"
        case .unsupportedOperator:
            return "Unsupported operator"
        case .unsupportedValue:
            return "Unsupported value"
        case .unsupportedJoin:
            return "Unsupported join"
        case .unsupportedJoinMethod:
            return "Unsupported join method"
        case .unsupportedFilter:
            return "Unsupported filter"
        case .unsupportedFilterRelation:
            return "Unsupported filter relation"
        case .unsupportedQueryAction:
            return "Unsupported query action"
        case .unsupportedSort:
            return "Unsupported sort"
        case .unsupportedSortDirection:
            return "Unsupported sort direction"
        case .unsupportedOffset:
            return "Unsupported offset"
        case .unsupportedLimit:
            return "Unsupported limit"
        case .unsupportedAggregate:
            return "Unsupported aggregate"
        case .unsupportedAggregateMethod:
            return "Unsupported aggregate method"
        }
    }

    public var errorDescription: String? {
        return self.description
    }

    public var isSyntaxError: Bool {
        switch self {
        case .duplicatedKey,
             .invalidNestedDocument,
             .invalidResult,
             .insertManyMismatch:
            return false
        case .collectionNotFound,
             .unsupportedField,
             .unsupportedFieldName,
             .unsupportedOperator,
             .unsupportedValue,
             .unsupportedJoin,
             .unsupportedJoinMethod,
             .unsupportedFilter,
             .unsupportedFilterRelation,
             .unsupportedQueryAction,
             .unsupportedSort,
             .unsupportedSortDirection,
             .unsupportedOffset,
             .unsupportedLimit,
             .unsupportedAggregate,
            .unsupportedAggregateMethod:
            return true
        }
    }

    public var isConstraintFailure: Bool {
        switch self {
        case .duplicatedKey:
            return true
        default:
            return false
        }
    }

    public var isConnectionClosed: Bool {
        return false
    }
}

extension EventLoopFuture where Value: Model {

    @discardableResult
    public func flatMapErrorIfDuplicatedKey(_ callback: @escaping (Error) -> EventLoopFuture<Value>) -> EventLoopFuture<Value> {
        return self.flatMapError { error in
            guard
                let mongoError = error as? Error,
                case .duplicatedKey = mongoError
                else {
                    return self.eventLoop.makeFailedFuture(error)
            }

            return callback(mongoError)
        }
    }

    @discardableResult
    public func flatMapErrorThrowingIfDuplicatedKey(_ callback: @escaping (Error) throws -> Value) -> EventLoopFuture<Value> {
        return self.flatMapErrorThrowing { error in
            guard
                let mongoError = error as? Error,
                case .duplicatedKey = mongoError
                else {
                    throw error
            }

            return try callback(mongoError)
        }
    }
}

extension MongoError.WriteError {
    var isDuplicatedKeyError: Bool {
        return self.writeFailure?.code == 11000 || self.writeConcernFailure?.code == 11000
    }
}

extension MongoError.BulkWriteError {
    var isDuplicatedKeyError: Bool {
        switch (self.writeFailures, self.writeConcernFailure) {
        case (_, .some(let failure)):
            return failure.code == 11000
        case (.some(let failures), _):
            return failures.contains { $0.code == 11000 }
        default:
            return false
        }
    }
}

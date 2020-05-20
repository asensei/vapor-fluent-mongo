//
//  Error.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 18/05/2020.
//  Copyright © 2020 Asensei Inc. All rights reserved.
//

import Foundation

public enum Error: Swift.Error, LocalizedError, CustomStringConvertible {
    case invalidResult
    case insertManyMismatch(Int, Int)
    case unsupportedField
    case unsupportedOperator
    case unsupportedValue
    case unsupportedJoin
    case unsupportedJoinMethod

    public var description: String {
        switch self {
        case .invalidResult:
            return "Query returned no results"
        case .insertManyMismatch(let count, let expected):
            return "Inserted \(count) documents out of \(expected)"
        case .unsupportedField:
            return "Unsupported field"
        case .unsupportedOperator:
            return "Unsupported operator"
        case .unsupportedValue:
            return "Unsupported value"
        case .unsupportedJoin:
            return "Unsupported join"
        case .unsupportedJoinMethod:
            return "Unsupported join method"
        }
    }

    public var errorDescription: String? {
        return self.description
    }
}

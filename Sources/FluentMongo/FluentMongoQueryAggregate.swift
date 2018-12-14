//
//  FluentMongoQueryAggregate.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 11/12/2018.
//  Copyright © 2018 Asensei Inc. All rights reserved.
//

import Foundation
import Fluent

// MARK: - QueryAggregate

public enum FluentMongoQueryAggregate {
    case count
    case group(AccumulatorOperator)

    var value: String {
        switch self {
        case .count:
            return "$count"
        case .group:
            return "$group"
        }
    }

    public enum AccumulatorOperator: String {
        /// Returns an array of unique expression values for each group. Order of the array elements is undefined.
        case addToSet
        /// Returns an average of numerical values. Ignores non-numeric values.
        case avg
        /// Returns a value from the first document for each group. Order is only defined if the documents are in a defined order.
        case first
        /// Returns a value from the last document for each group. Order is only defined if the documents are in a defined order.
        case last
        /// Returns the highest expression value for each group.
        case max
        /// Returns a document created by combining the input documents for each group.
        case mergeObjects
        /// Returns the lowest expression value for each group.
        case min
        /// Returns an array of expression values for each group.
        case push
        /// Returns the population standard deviation of the input values.
        case stdDevPop
        /// Returns the sample standard deviation of the input values.
        case stdDevSamp
        /// Returns a sum of numerical values. Ignores non-numeric values.
        case sum

        var value: String {
            return "$" + self.rawValue
        }
    }
}

extension Database where Self: QuerySupporting, Self.QueryAggregate == FluentMongoQueryAggregate {
    public static var queryAggregateCount: FluentMongoQueryAggregate {
        return .count
    }

    public static var queryAggregateSum: FluentMongoQueryAggregate {
        return .group(.sum)
    }

    public static var queryAggregateAverage: FluentMongoQueryAggregate {
        return .group(.avg)
    }

    public static var queryAggregateMinimum: FluentMongoQueryAggregate {
        return .group(.min)
    }

    public static var queryAggregateMaximum: FluentMongoQueryAggregate {
        return .group(.max)
    }
}

extension Database where Self: QuerySupporting, Self.QueryAggregate == FluentMongoQueryAggregate, Self.QueryKey == FluentMongoQueryKey {

    public static func queryAggregate(_ aggregate: QueryAggregate, _ fields: [QueryKey]) -> QueryKey {
        return .computed(aggregate, fields)
    }
}

//
//  DatabaseQueryAggregate+Mongo.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 21/05/2020.
//  Copyright © 2020 Asensei Inc. All rights reserved.
//

import Foundation
import FluentKit

extension DatabaseQuery.Aggregate {

    func mongoAggregate(encoder: BSONEncoder) throws -> BSON {
        switch self {
        case .field(let field, let method):
            fatalError()
        case .custom:
            fatalError()
        }
    }
}

extension DatabaseQuery.Aggregate.Method: Equatable {

    func mongoAccumulatorOperator() throws -> String {
        switch self {
        case .count:
            return "$count"
        case .sum:
            return "$sum"
        case .average:
            return "$avg"
        case .minimum:
            return "$min"
        case .maximum:
            return "$max"
        case .custom(let value as MongoAccumulatorOperator):
            return value.rawValue
        case .custom(let value as String):
            return value
        case .custom:
            throw Error.unsupportedAggregateMethod
        }
    }

    public enum MongoAccumulatorOperator: String {
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

    public static var addToSet: DatabaseQuery.Aggregate.Method {
        return .custom(MongoAccumulatorOperator.addToSet)
    }

    public static var avg: DatabaseQuery.Aggregate.Method {
        return .custom(MongoAccumulatorOperator.avg)
    }

    public static var first: DatabaseQuery.Aggregate.Method {
        return .custom(MongoAccumulatorOperator.first)
    }

    public static var last: DatabaseQuery.Aggregate.Method {
        return .custom(MongoAccumulatorOperator.last)
    }

    public static var max: DatabaseQuery.Aggregate.Method {
        return .custom(MongoAccumulatorOperator.max)
    }

    public static var mergeObjects: DatabaseQuery.Aggregate.Method {
        return .custom(MongoAccumulatorOperator.mergeObjects)
    }

    public static var min: DatabaseQuery.Aggregate.Method {
        return .custom(MongoAccumulatorOperator.min)
    }

    public static var push: DatabaseQuery.Aggregate.Method {
        return .custom(MongoAccumulatorOperator.push)
    }

    public static var stdDevPop: DatabaseQuery.Aggregate.Method {
        return .custom(MongoAccumulatorOperator.stdDevPop)
    }

    public static var stdDevSamp: DatabaseQuery.Aggregate.Method {
        return .custom(MongoAccumulatorOperator.stdDevSamp)
    }

    public static func ==(lhs: DatabaseQuery.Aggregate.Method, rhs: DatabaseQuery.Aggregate.Method) -> Bool {
        switch (lhs, rhs) {
        case (.count, .count),
             (.sum, .sum),
             (.average, .average),
             (.minimum, .minimum),
             (.maximum, .maximum),
             (.addToSet, .addToSet),
             (.avg, .avg), (.avg, .average), (.average, .avg),
             (.first, .first),
             (.last, .last),
             (.max, .max), (.max, .maximum), (.maximum, .max),
             (.mergeObjects, .mergeObjects),
             (.min, .min), (.min, .minimum), (.minimum, .min),
             (.push, .push),
             (.stdDevPop, .stdDevPop),
             (.stdDevSamp, .stdDevSamp),
             (.custom(MongoAccumulatorOperator.sum), .sum), (.sum, .custom(MongoAccumulatorOperator.sum)):
            return true
        default:
            return false
        }
    }
}

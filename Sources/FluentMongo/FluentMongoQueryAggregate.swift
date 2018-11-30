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
    case sum
    case average
    case minimum
    case maximum
}

extension Database where Self: QuerySupporting, Self.QueryAggregate == FluentMongoQueryAggregate {
    public static var queryAggregateCount: FluentMongoQueryAggregate {
        return .count
    }

    public static var queryAggregateSum: FluentMongoQueryAggregate {
        return .sum
    }

    public static var queryAggregateAverage: FluentMongoQueryAggregate {
        return .average
    }

    public static var queryAggregateMinimum: FluentMongoQueryAggregate {
        return .minimum
    }

    public static var queryAggregateMaximum: FluentMongoQueryAggregate {
        return .maximum
    }
}

//
//  FluentMongoQueryKey.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 11/12/2018.
//  Copyright © 2018 Asensei Inc. All rights reserved.
//

import Foundation
import Fluent

// MARK: - QueryKey

public typealias FluentMongoQueryKey = String

extension Database where Self: QuerySupporting, Self.QueryKey == FluentMongoQueryKey {

    public static var queryKeyAll: QueryKey {
        fatalError()
    }

    public static func queryAggregate(_ aggregate: QueryAggregate, _ fields: [QueryKey]) -> QueryKey {
        fatalError()
    }

    public static func queryKey(_ field: QueryField) -> QueryKey {
        fatalError()
    }

    public static func queryKeyApply(_ key: QueryKey, to query: inout Query) {
        fatalError()
    }
}

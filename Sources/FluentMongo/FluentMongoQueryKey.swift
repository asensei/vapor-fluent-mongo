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

public indirect enum FluentMongoQueryKey {
    case all
    case raw(String)
    case computed(FluentMongoQueryAggregate, [FluentMongoQueryKey])

    public typealias Computed = (aggregate: FluentMongoQueryAggregate, keys: [FluentMongoQueryKey])

    public var raw: String? {
        switch self {
        case .raw(let value):
            return value
        default:
            return nil
        }
    }

    public var computed: Computed? {
        switch self {
        case .computed(let aggregate, let keys):
            return (aggregate: aggregate, keys: keys)
        default:
            return nil
        }
    }
}

extension Array where Element == FluentMongoQueryKey {

    public var raw: [String] {
        return self.compactMap { $0.raw }
    }

    public var computed: [FluentMongoQueryKey.Computed] {
        return self.compactMap { $0.computed }
    }
}

extension Database where Self: QuerySupporting, Self.QueryKey == FluentMongoQueryKey {

    public static var queryKeyAll: QueryKey {
        return .all
    }
}

extension Database where Self: QuerySupporting, Self.QueryKey == FluentMongoQueryKey, Self.QueryField == FluentMongoQueryField {

    public static func queryKey(_ field: QueryField) -> QueryKey {
        return .raw(field.path.joined(separator: "."))
    }
}

extension Database where Self: QuerySupporting, Self.Query == FluentMongoQuery, Self.QueryKey == FluentMongoQueryKey {

    public static func queryKeyApply(_ key: QueryKey, to query: inout Query) {
        query.keys.append(key)
    }
}

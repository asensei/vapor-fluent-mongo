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

public enum FluentMongoQueryKey {
    case all
    case field(String)
}

//public typealias FluentMongoQueryKey = Document

extension Database where Self: QuerySupporting, Self.QueryKey == FluentMongoQueryKey {

    public static var queryKeyAll: QueryKey {
        return .all
    }
}

extension Database where Self: QuerySupporting, Self.QueryKey == FluentMongoQueryKey, Self.QueryField == FluentMongoQueryField {

    public static func queryKey(_ field: QueryField) -> QueryKey {
        return .field(field.path.joined(separator: "."))
    }
}

extension Database where Self: QuerySupporting, Self.Query == FluentMongoQuery, Self.QueryKey == FluentMongoQueryKey {

    public static func queryKeyApply(_ key: QueryKey, to query: inout Query) {
        switch key {
        case .all:
            query.projection = nil
        case .field(let value):
            var document = query.projection ?? Document()
            document[value] = 1
            query.projection = document
        }
    }
}

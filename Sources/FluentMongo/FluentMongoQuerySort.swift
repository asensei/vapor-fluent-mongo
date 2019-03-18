//
//  FluentMongoQuerySort.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 18/12/2018.
//  Copyright © 2018 Asensei Inc. All rights reserved.
//

import Foundation
import Fluent
import MongoSwift

// MARK: - QuerySort

public typealias FluentMongoQuerySort = Document

public enum FluentMongoQuerySortDirection: Int {
    case ascending = 1
    case descending = -1
}

extension Database where Self: QuerySupporting, Self.QuerySort == FluentMongoQuerySort, Self.QuerySortDirection == FluentMongoQuerySortDirection, Self.QueryField == FluentMongoQueryField {

    public static func querySort(_ field: QueryField, _ direction: QuerySortDirection) -> QuerySort {
        var document = Document()
        document[field.pathWithNamespace.joined(separator: ".")] = direction.rawValue

        return document
    }
}

extension Database where Self: QuerySupporting, Self.Query == FluentMongoQuery, Self.QuerySort == FluentMongoQuerySort {

    public static func querySortApply(_ sort: QuerySort, to query: inout Query) {
        var document = query.sort ?? Document()
        for field in sort {
            document[field.key] = field.value
        }
        query.sort = document.byRemovingKeysPrefix(query.collection)
    }
}

extension Database where Self: QuerySupporting, Self.QuerySortDirection == FluentMongoQuerySortDirection {

    public static var querySortDirectionAscending: QuerySortDirection {
        return .ascending
    }

    public static var querySortDirectionDescending: QuerySortDirection {
        return .descending
    }
}

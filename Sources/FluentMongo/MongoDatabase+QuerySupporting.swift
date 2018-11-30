//
//  MongoDatabase+QuerySupporting.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 03/12/2018.
//  Copyright © 2018 Asensei Inc. All rights reserved.
//

import Foundation
import Fluent
import MongoSwift

extension MongoDatabase: QuerySupporting {


    public typealias Query = FluentMongoQuery

    public typealias Output = FluentMongoOutput

    public typealias QueryAction = FluentMongoQueryAction

    public typealias QueryAggregate = FluentMongoQueryAggregate

    public typealias QueryData = FluentMongoQueryData

    public typealias QueryField = FluentMongoQueryField

    public typealias QueryFilter = FluentMongoQueryFilter

    public typealias QueryFilterMethod = FluentMongoQueryFilterMethod

    public typealias QueryFilterValue = FluentMongoQueryFilterValue?

    public typealias QueryFilterRelation = FluentMongoQueryFilterRelation

    public static func queryExecute(_ query: Query, on conn: Connection, into handler: @escaping (Output, Connection) throws -> ()) -> Future<Void> {
        return conn.query(query) { try handler($0, conn) }
    }

    public static func modelEvent<M: Model>(event: ModelEvent, model: M, on conn: Connection) -> Future<M> where M.Database == MongoDatabase {
            var copy = model
            switch event {
            case .willCreate where M.ID.self is UUID.Type && copy.fluentID == nil:
                copy.fluentID = UUID() as? M.ID
            default:
                break
            }

            return conn.future(copy)
    }
}

// MARK: - Key

public extension MongoDatabase {

    public typealias QueryKey = String

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

    public static func queryRangeApply(lower: Int, upper: Int?, to query: inout Query) {
        fatalError()
    }
}

// MARK: - Sort

public extension MongoDatabase {

    public typealias QuerySort = String

    public typealias QuerySortDirection = String

    public static func querySort(_ field: QueryField, _ direction: QuerySortDirection) -> QuerySort {
        fatalError()
    }

    public static var querySortDirectionAscending: QuerySortDirection {
        fatalError()
    }

    public static var querySortDirectionDescending: QuerySortDirection {
        fatalError()
    }

    public static func querySortApply(_ sort: QuerySort, to query: inout Query) {
        fatalError()
    }
}

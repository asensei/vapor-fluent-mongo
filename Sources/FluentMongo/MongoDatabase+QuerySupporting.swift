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

    public typealias QueryKey = FluentMongoQueryKey

    public typealias QuerySort = FluentMongoQuerySort

    public typealias QuerySortDirection = FluentMongoQuerySortDirection

    public static func queryExecute(_ query: Query, on conn: Connection, into handler: @escaping (Output, Connection) throws -> Void) -> Future<Void> {
        return conn.query(query) { try handler($0, conn) }
    }

    public static func modelEvent<M: Model>(event: ModelEvent, model: M, on conn: Connection) -> Future<M> where M.Database == MongoDatabase {
            var copy = model
            switch event {
            case .willCreate where M.ID.self is UUID.Type && copy.fluentID == nil:
                copy.fluentID = UUID() as? M.ID
            case .willCreate where M.ID.self is Int.Type && copy.fluentID == nil:
                return M.query(on: conn).max(M.idKey).map { id in
                    switch id {
                    case .some(let value as Int):
                        copy.fluentID = (value + 1) as? M.ID
                    case .none:
                        copy.fluentID = 0 as? M.ID
                    default:
                        break
                    }

                    return copy
                }

            default:
                break
            }

            return conn.future(copy)
    }
}

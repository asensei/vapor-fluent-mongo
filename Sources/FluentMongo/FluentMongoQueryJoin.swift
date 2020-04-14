//
//  FluentMongoQueryJoin.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 19/12/2018.
//  Copyright © 2018 Asensei Inc. All rights reserved.
//

import Foundation
import Fluent
import MongoSwift

public typealias FluentMongoQueryJoin = [Document]

public enum FluentMongoQueryJoinMethod {
    case inner
    case outer
}

extension Database where Self: JoinSupporting, Self.QueryJoin == FluentMongoQueryJoin, Self.Query == FluentMongoQuery {

    public static func queryJoinApply(_ join: QueryJoin, to query: inout Query) {
        query.joins.append(contentsOf: join)
    }
}

extension Database where Self: JoinSupporting, Self.QueryJoin == FluentMongoQueryJoin, Self.QueryJoinMethod == FluentMongoQueryJoinMethod, Self.QueryField == FluentMongoQueryField {

    public static func queryJoin(_ method: QueryJoinMethod, base: QueryField, joined: QueryField) -> QueryJoin {
        guard let collection = joined.entity else {
            return []
        }

        let lookup: Document = [
            "$lookup": [
                "from": .string(collection),
                "localField": .string(base.path.joined(separator: ".")),
                "foreignField": .string(joined.path.joined(separator: ".")),
                "as": .string(collection)
            ]
        ]

        let unwind: Document = [
            "$unwind": [
                "path": .string("$" + collection),
                "preserveNullAndEmptyArrays": .bool(method == .outer)
            ]
        ]

        return [lookup, unwind]
    }
}

extension Database where Self: JoinSupporting, Self.QueryJoinMethod == FluentMongoQueryJoinMethod {

    public static var queryJoinMethodDefault: QueryJoinMethod {
        return .inner
    }
}

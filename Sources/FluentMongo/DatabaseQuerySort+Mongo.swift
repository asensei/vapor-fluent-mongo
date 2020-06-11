//
//  DatabaseQuerySort+Mongo.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 21/05/2020.
//  Copyright © 2020 Asensei Inc. All rights reserved.
//

import Foundation
import FluentKit

extension DatabaseQuery.Sort {

    func mongoSort(mainSchema: String) throws -> (key: String, value: Int) {
        switch self {
        case .sort(let field, let direction):
            return try (
                key: field.mongoKeyPath(namespace: field.schema != mainSchema),
                value: direction.mongoSortDirection()
            )
        case .custom(let value as (key: String, value: Int)):
            return value
        case .custom:
            throw Error.unsupportedSort
        }
    }
}

extension Array where Element == DatabaseQuery.Sort {

    func mongoSort(mainSchema: String) throws -> [BSONDocument] {
        let document = try self.reduce(into: BSONDocument()) { document, sort in
            let result = try sort.mongoSort(mainSchema: mainSchema)
            document[result.key] = .init(result.value)
        }

        guard !document.isEmpty else {
            return []
        }

        return [["$sort": .document(document)]]
    }
}

extension DatabaseQuery.Sort.Direction {

    func mongoSortDirection() throws -> Int {
        switch self {
        case .ascending:
            return 1
        case .descending:
            return -1
        case .custom(let value as Int):
            return value
        case .custom:
            throw Error.unsupportedSortDirection
        }
    }
}

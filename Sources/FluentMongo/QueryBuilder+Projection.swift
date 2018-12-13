//
//  QueryBuilder+Projection.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 12/12/2018.
//  Copyright © 2018 Asensei Inc. All rights reserved.
//

import Foundation
import Fluent

extension QueryBuilder where Database == MongoDatabase {

    public func project<T>(field: KeyPath<Result, T>) -> Self {
        self.queryProjectionApply(properties: [FluentProperty.keyPath(field).path])

        return self
    }

    public func project<D: Decodable>(_ type: D.Type, depth: Int = 0) throws -> QueryBuilder<Database, D> {
        let properties = try type.decodeProperties(depth: depth).map { $0.path }
        self.queryProjectionApply(properties: properties)

        return self.decode(data: D.self, Database.queryEntity(for: self.query))

    }

    private func queryProjectionApply(properties: [[String]]) {
        guard !properties.isEmpty else {
            self.query.projection = nil

            return
        }

        var projection = self.query.projection ?? Document()

        for property in properties {
            projection[property.joined(separator: ".")] = 1
        }

        self.query.projection = projection
    }
}

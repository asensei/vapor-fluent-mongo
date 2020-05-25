//
//  QueryBuilder+Mongo.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 25/05/2020.
//  Copyright © 2020 Asensei Inc. All rights reserved.
//

import Foundation
import FluentKit

extension QueryBuilder {

    @discardableResult
    public func set<Field>(
        _ field: KeyPath<Model, Field>,
        addToSet values: Field.Value
    ) -> Self
        where
        Field: FieldProtocol,
        Field.Value: Collection,
        Field.Value.Element: Encodable,
        Field.Model == Model
    {
        if self.query.input.isEmpty {
            self.query.input = [.dictionary([:])]
        }

        var existing = self.query.input[.addToSet] ?? [:]
        existing[.string(Model.path(for: field).mongoKeys.dotNotation)] = .dictionary([
            .string("$each"): .array(values.map { .bind($0) })
        ])

        self.query.input[.addToSet] = existing

        return self
    }
}

extension Array where Element == DatabaseQuery.Value {

    subscript(_ op: DatabaseQuery.Value.MongoUpdateArrayOperator) -> [FieldKey: DatabaseQuery.Value]? {
        get {
            for element in self {
                guard let existing = element.mongoUpdateArrayOperatorValue(op) else {
                    continue
                }

                return existing
            }

            return nil
        }
        set(newValue) {
            guard let index = self.firstIndex(where: { $0.mongoUpdateArrayOperatorValue(op) != nil }) else {
                if let newValue = newValue {
                    self.append(op.databaseQueryValue(newValue))
                }

                return
            }

            if let newValue = newValue {
                self[index] = op.databaseQueryValue(newValue)
            } else {
                self.remove(at: index)
            }
        }
    }
}

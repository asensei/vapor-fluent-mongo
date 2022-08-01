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
    public func filter(
        keywords: String,
        language: String? = nil,
        caseSensitive: Bool? = nil,
        diacriticSensitive: Bool? = nil
    ) -> Self {
        self.query.filters.append(.text(.init(
            search: keywords,
            language: language,
            caseSensitive: caseSensitive,
            diacriticSensitive: diacriticSensitive
        )))

        return self
    }

    /// Adds elements to an array only if they do not already exist in the set.
    @discardableResult
    public func set<Field>(
        _ field: KeyPath<Model, Field>,
        addToSet values: Field.Value
    ) -> Self
        where
        Field: QueryableProperty,
        Field.Value: Collection,
        Field.Value.Element: Encodable,
        Field.Model == Model {

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

    /// Adds elements to an array only if they do not already exist in the set.
    @discardableResult
    public func set<Field>(
        _ field: KeyPath<Model, Field>,
        addToSet values: Field.Value.Wrapped
    ) -> Self
        where
        Field: QueryableProperty,
        Field.Value: OptionalType,
        Field.Value.Wrapped: Collection,
        Field.Value.Wrapped.Element: Encodable,
        Field.Model == Model {

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

    /// Adds elements to an array.
    @discardableResult
    public func set<Field>(
        _ field: KeyPath<Model, Field>,
        push values: Field.Value
    ) -> Self
        where
        Field: QueryableProperty,
        Field.Value: Collection,
        Field.Value.Element: Encodable,
        Field.Model == Model {

        if self.query.input.isEmpty {
            self.query.input = [.dictionary([:])]
        }

        var existing = self.query.input[.push] ?? [:]
        existing[.string(Model.path(for: field).mongoKeys.dotNotation)] = .dictionary([
            .string("$each"): .array(values.map { .bind($0) })
        ])

        self.query.input[.push] = existing

        return self
    }

    /// Adds elements to an array.
    @discardableResult
    public func set<Field>(
        _ field: KeyPath<Model, Field>,
        push values: Field.Value.Wrapped
    ) -> Self
        where
        Field: QueryableProperty,
        Field.Value: OptionalType,
        Field.Value.Wrapped: Collection,
        Field.Value.Wrapped.Element: Encodable,
        Field.Model == Model {

        if self.query.input.isEmpty {
            self.query.input = [.dictionary([:])]
        }

        var existing = self.query.input[.push] ?? [:]
        existing[.string(Model.path(for: field).mongoKeys.dotNotation)] = .dictionary([
            .string("$each"): .array(values.map { .bind($0) })
        ])

        self.query.input[.push] = existing

        return self
    }

    /// Removes all matching values from an array.
    @discardableResult
    public func set<Field>(
        _ field: KeyPath<Model, Field>,
        pullAll values: Field.Value
    ) -> Self
        where
        Field: QueryableProperty,
        Field.Value: Collection,
        Field.Value.Element: Encodable,
        Field.Model == Model {

        if self.query.input.isEmpty {
            self.query.input = [.dictionary([:])]
        }

        var existing = self.query.input[.pullAll] ?? [:]
        existing[.string(Model.path(for: field).mongoKeys.dotNotation)] = .array(values.map { .bind($0) })

        self.query.input[.pullAll] = existing

        return self
    }

    /// Removes all matching values from an array.
    @discardableResult
    public func set<Field>(
        _ field: KeyPath<Model, Field>,
        pullAll values: Field.Value.Wrapped
    ) -> Self
        where
        Field: QueryableProperty,
        Field.Value: OptionalType,
        Field.Value.Wrapped: Collection,
        Field.Value.Wrapped.Element: Encodable,
        Field.Model == Model {

        if self.query.input.isEmpty {
            self.query.input = [.dictionary([:])]
        }

        var existing = self.query.input[.pullAll] ?? [:]
        existing[.string(Model.path(for: field).mongoKeys.dotNotation)] = .array(values.map { .bind($0) })

        self.query.input[.pullAll] = existing

        return self
    }
}

extension Array where Element == DatabaseQuery.Value {

    fileprivate subscript(_ op: DatabaseQuery.Value.MongoUpdateArrayOperator) -> [FieldKey: DatabaseQuery.Value]? {
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

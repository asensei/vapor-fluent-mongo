//
//  QueryBuilder+Operators.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 18/01/2019.
//  Copyright © 2019 Asensei Inc. All rights reserved.
//

import Foundation
import FluentKit

extension QueryBuilder {
    @discardableResult
    public func filter<Field>(
        _ field: KeyPath<Model, Field>,
        _ method: DatabaseQuery.Filter.Method,
        _ value: Field.Value.Element
    ) -> Self where Field: QueryableProperty, Field.Value: Collection, Field.Value.Element: Codable, Field.Model == Model {
        self.filter(Model.path(for: field), method, [value])
    }

    @discardableResult
    public func filter<Field>(
        _ field: KeyPath<Model, Field>,
        _ method: DatabaseQuery.Filter.Method,
        _ value: Field.Value.Wrapped.Element
    ) -> Self where Field: QueryableProperty, Field.Value: OptionalType, Field.Value.Wrapped: Collection, Field.Value.Wrapped.Element: Codable, Field.Model == Model {
        self.filter(Model.path(for: field), method, [value])
    }
}

public func ~~ <Model, Field>(lhs: KeyPath<Model, Field>, rhs: Field.Value.Element) -> ModelValueFilter<Model>
    where Model: FluentKit.Model,
        Field: QueryableProperty,
        Field.Value: Collection,
        Field.Value.Element: Codable {
    lhs ~~ .array([.bind(rhs)])
}

public func ~~ <Model, Field>(lhs: KeyPath<Model, Field>, rhs: Field.Value.Wrapped.Element) -> ModelValueFilter<Model>
    where Model: FluentKit.Model,
        Field: QueryableProperty,
        Field.Value: OptionalType,
        Field.Value.Wrapped: Collection,
        Field.Value.Wrapped.Element: Codable {
    lhs ~~ .array([.bind(rhs)])
}

public func !~ <Model, Field>(lhs: KeyPath<Model, Field>, rhs: Field.Value.Element) -> ModelValueFilter<Model>
    where Model: FluentKit.Model,
        Field: QueryableProperty,
        Field.Value: Collection,
        Field.Value.Element: Codable {
    lhs !~ .array([.bind(rhs)])
}

public func !~ <Model, Field>(lhs: KeyPath<Model, Field>, rhs: Field.Value.Wrapped.Element) -> ModelValueFilter<Model>
    where Model: FluentKit.Model,
        Field: QueryableProperty,
        Field.Value: OptionalType,
        Field.Value.Wrapped: Collection,
        Field.Value.Wrapped.Element: Codable {
    lhs !~ .array([.bind(rhs)])
}

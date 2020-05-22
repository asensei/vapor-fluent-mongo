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
    ) -> Self
        where Field: FieldProtocol, Field.Value: Collection, Field.Value.Element: Codable, Field.Model == Model
    {
        self.filter(Model.path(for: field), method, [value])
    }
}

public func ~~ <Model, Field>(lhs: KeyPath<Model, Field>, rhs: Field.Value.Element) -> ModelValueFilter<Model>
    where Model: FluentKit.Model,
        Field: FieldProtocol,
        Field.Value: Collection,
        Field.Value.Element: Codable
{
    lhs ~~ .array([.bind(rhs)])
}

//
//  QueryBuilder+Distinct.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 18/12/2018.
//  Copyright © 2018 Asensei Inc. All rights reserved.
//

import Foundation
import Fluent

extension QueryBuilder where Database.Query == FluentMongoQuery {

    public func distinct(_ value: Bool = true) -> Self {
        self.query.isDistinct = value

        return self
    }
}

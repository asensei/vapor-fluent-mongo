//
//  QueryBuilder+Options.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 11/04/2019.
//  Copyright © 2018 Asensei Inc. All rights reserved.
//

import Foundation
import Fluent
import MongoSwift

public extension QueryBuilder where Database.Query == FluentMongoQuery {

    /// Enables writing to temporary files. When set to true, aggregation stages can write data to the _tmp subdirectory in the dbPath directory.
    @discardableResult
    public func allowDiskUse(_ value: Bool = true) -> Self {
        let previous = self.query.aggregateOptions
        let options = AggregateOptions(
            allowDiskUse: value,
            batchSize: previous?.batchSize,
            bypassDocumentValidation: previous?.bypassDocumentValidation,
            collation: previous?.collation,
            comment: previous?.comment,
            hint: previous?.hint,
            maxTimeMS: previous?.maxTimeMS,
            readConcern: previous?.readConcern,
            readPreference: previous?.readPreference,
            writeConcern: previous?.writeConcern
        )

        self.query.aggregateOptions = options

        return self
    }
}

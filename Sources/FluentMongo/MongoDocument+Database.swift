//
//  MongoDocument+Database.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 21/10/2019.
//  Copyright © 2019 Asensei Inc. All rights reserved.
//

import Foundation
import FluentKit
import MongoSwift
/*
public typealias MongoDocument = Document

extension Document: DatabaseRow {

    public func contains(field: String) -> Bool {
        return self.hasKey(field)
    }

    public func decode<T>(field: String, as type: T.Type, for database: Database) throws -> T where T: Decodable {

        guard let driver = database.driver as? MongoDatabaseDriver else {
            throw DecodingError.typeMismatch(MongoDatabaseDriver.self, .init(codingPath: [], debugDescription: "Database.driver is not of type \"MongoDatabaseDriver\"."))
        }

        return try driver.decoder.decode(T.self, from: self, forKey: field)
    }
}
*/
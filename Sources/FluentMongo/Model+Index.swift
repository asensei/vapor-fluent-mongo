//
//  Model+Index.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 21/12/2018.
//  Copyright © 2018 Asensei Inc. All rights reserved.
//

import Foundation
import Fluent

extension Model where Database == MongoDatabase {
    public static func index(on conn: Database.Connection) -> IndexBuilder<Self> {
        return IndexBuilder(on: conn.databaseConnection(to: Self.defaultDatabase))
    }

    public static func index(on conn: DatabaseConnectable) -> IndexBuilder<Self> {
        return IndexBuilder(on: conn.databaseConnection(to: Self.defaultDatabase))
    }
}

//
//  MongoDatabase+MigrationSupporting.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 21/12/2018.
//  Copyright © 2018 Asensei Inc. All rights reserved.
//

import Foundation
import Fluent

extension MongoDatabase: MigrationSupporting {

    /// See `MigrationSupporting`.
    public static func prepareMigrationMetadata(on conn: Connection) -> Future<Void> {
        return conn.prepareMigrationMetadata()
    }

    /// See `MigrationSupporting`.
    public static func revertMigrationMetadata(on conn: Connection) -> Future<Void> {
        return conn.revertMigrationMetadata()
    }
}

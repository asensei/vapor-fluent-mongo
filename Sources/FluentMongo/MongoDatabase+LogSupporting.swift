//
//  MongoDatabase+LogSupporting.swift
//  Fluent
//
//  Created by Valerio Mazzeo on 03/12/2018.
//  Copyright © 2018 Asensei Inc. All rights reserved.
//

import Foundation
import Fluent

extension MongoDatabase: LogSupporting {
    /// See `LogSupporting`.
    public static func enableLogging(_ logger: DatabaseLogger, on conn: MongoConnection) {
        conn.logger = logger
    }
}

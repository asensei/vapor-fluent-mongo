//
//  MongoConnection+Connect.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 30/11/2018.
//  Copyright © 2018 Asensei Inc. All rights reserved.
//

import Foundation
import Async

public extension MongoConnection {

    public static func connect(config: MongoDatabaseConfig, on worker: Worker) -> Future<MongoConnection> {
        do {
            return try worker.future(MongoConnection(config: config, on: worker))
        } catch {
            return worker.future(error: error)
        }
    }
}

//
//  User.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 18/12/2018.
//  Copyright © 2018 Asensei Inc. All rights reserved.
//

import Foundation
import FluentMongo

final class User: FluentMongoModel {

    typealias Database = MongoDatabase

    typealias ID = UUID

    var _id: UUID?
    var name: String = ""

    init(_id: UUID? = nil, name: String) {
        self._id = _id
        self.name = name
    }
}

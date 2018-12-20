//
//  User.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 18/12/2018.
//  Copyright © 2018 Asensei Inc. All rights reserved.
//

import Foundation
import FluentMongo

final class User: FluentMongoModel, Model {

    typealias Database = MongoDatabase

    typealias ID = UUID

    var _id: UUID?
    var name: String
    var age: Int?

    init(_id: UUID? = nil, name: String, age: Int? = nil) {
        self._id = _id
        self.name = name
        self.age = age
    }
}

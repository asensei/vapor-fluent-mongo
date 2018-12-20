//
//  Pet.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 20/12/2018.
//  Copyright © 2018 Asensei Inc. All rights reserved.
//

import Foundation
import Fluent
import FluentMongo

final class Pet: FluentMongoModel, Model {

    typealias Database = MongoDatabase

    typealias ID = UUID

    var _id: UUID?
    var name: String
    var age: Int?
    var favoriteToyId: Toy.ID?

    init(_id: UUID? = nil, name: String, age: Int? = nil, favoriteToyId: Toy.ID? = nil) {
        self._id = _id
        self.name = name
        self.age = age
        self.favoriteToyId = favoriteToyId
    }

    var favoriteToy: Parent<Pet, Toy>? {
        return self.parent(\.favoriteToyId)
    }

    var toys: Siblings<Pet, Toy, PetToy> {
        return self.siblings()
    }
}

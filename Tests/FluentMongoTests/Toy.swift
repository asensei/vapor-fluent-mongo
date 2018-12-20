//
//  Toy.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 20/12/2018.
//  Copyright © 2018 Asensei Inc. All rights reserved.
//

import Foundation
import FluentMongo

final class Toy: FluentMongoModel, Model {

    typealias Database = MongoDatabase

    typealias ID = UUID

    var _id: UUID?
    var name: String
    var material: String?

    init(_id: UUID? = nil, name: String, material: String? = nil) {
        self._id = _id
        self.name = name
        self.material = material
    }

    var pets: Siblings<Toy, Pet, PetToy> {
        return self.siblings()
    }
}

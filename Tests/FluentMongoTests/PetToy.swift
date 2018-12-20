//
//  PetToy.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 20/12/2018.
//  Copyright © 2018 Asensei Inc. All rights reserved.
//

import Foundation
import Fluent
import FluentMongo

final class PetToy: FluentMongoModel, Pivot {

    typealias Database = MongoDatabase

    typealias ID = UUID

    typealias Left = Pet

    typealias Right = Toy

    static var leftIDKey: LeftIDKey = \.petId

    static var rightIDKey: RightIDKey = \.toyId

    var _id: UUID?
    var petId: Pet.ID
    var toyId: Toy.ID
}

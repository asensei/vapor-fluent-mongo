//
//  PetToy.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 20/12/2018.
//  Copyright © 2018 Asensei Inc. All rights reserved.
//

import Foundation
import FluentMongo

final class PetToy: Model {

    static let schema = "pet_toys"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "petId")
    var pet: Pet

    @Parent(key: "toyId")
    var toy: Toy
}

//
//  Toy.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 20/12/2018.
//  Copyright © 2018 Asensei Inc. All rights reserved.
//

import Foundation
import FluentMongo

final class Toy: Model {

    static let schema = "toys"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @OptionalField(key: "material")
    var material: String?

    @Siblings(through: PetToy.self, from: \.$toy, to: \.$pet)
    var pets: [Pet]

    init(id: UUID? = nil, name: String, material: String? = nil) {
        self.id = id
        self.name = name
        self.material = material
    }

    init() { }
}

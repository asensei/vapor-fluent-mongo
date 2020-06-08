//
//  Pet.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 20/12/2018.
//  Copyright © 2018 Asensei Inc. All rights reserved.
//

import Foundation
import FluentMongo

final class Pet: Model {

    static let schema = "pets"

    @ID(key: .id)
    public var id: UUID?

    @Field(key: "name")
    var name: String

    @OptionalField(key: "age")
    var age: Int?

    @OptionalParent(key: "favoriteToyId")
    var favoriteToy: Toy?

    @Siblings(through: PetToy.self, from: \.$pet, to: \.$toy)
    var toys: [Toy]

    init(id: UUID? = nil, name: String, age: Int? = nil, favoriteToyId: Toy.IDValue? = nil) {
        self.id = id
        self.name = name
        self.age = age
        self.$favoriteToy.id = favoriteToyId
    }

    init() { }
}

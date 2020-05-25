//
//  User.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 18/12/2018.
//  Copyright © 2018 Asensei Inc. All rights reserved.
//

import Foundation
import FluentMongo

final class User: Model {

    static let schema = "users"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @OptionalField(key: "age")
    var age: Int?

    @OptionalField(key: "names")
    var names: [String]?

    @OptionalField(key: "nicknames")
    var nicknames: Set<String>?

    @OptionalField(key: "updatedAt")
    var updatedAt: Date?

    @OptionalField(key: "nested")
    var nested: Nested?

    struct Nested: Codable {
        let p1: String
    }

    init(id: UUID? = nil, name: String, age: Int? = nil, names: [String]? = nil, nicknames: Set<String>? = nil, nested: Nested? = nil) {
        self.id = id
        self.name = name
        self.age = age
        self.names = names
        self.nicknames = nicknames
        self.nested = nested
    }

    init() { }
}

extension User: Equatable {
    static func == (lhs: User, rhs: User) -> Bool {
        guard let lhsId = lhs.id, let rhsId = rhs.id else {
            return false
        }

        return lhsId == rhsId
    }
}

extension User {

    class SetAgeMigration: Migration {

        func prepare(on database: Database) -> EventLoopFuture<Void> {
            return User.query(on: database).set(\.$age, to: 99).update()
        }

        func revert(on database: Database) -> EventLoopFuture<Void> {
            // TODO: https://github.com/vapor/fluent-kit/issues/284
            //return User.query(on: database).set(\.$age, to: nil).update()
            return database.eventLoop.makeSucceededFuture(Void())
        }
    }
}

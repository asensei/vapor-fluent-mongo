//
//  User.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 18/12/2018.
//  Copyright © 2018 Asensei Inc. All rights reserved.
//

import Foundation
import Fluent
import FluentMongo

final class User: FluentMongoModel, Model {

    //static let updatedAtKey: TimestampKey? = \.updatedAt

    typealias Database = MongoDatabase

    typealias ID = UUID

    var _id: UUID?
    var name: String
    var age: Int?
    var nicknames: Set<String>?
    var updatedAt: Date?

    init(_id: UUID? = nil, name: String, age: Int? = nil, nicknames: Set<String>? = nil) {
        self._id = _id
        self.name = name
        self.age = age
        self.nicknames = nicknames
    }
}

extension User: Equatable {
    static func == (lhs: User, rhs: User) -> Bool {
        guard let lhsId = lhs._id, let rhsId = rhs._id else {
            return false
        }

        return lhsId == rhsId
    }
}

extension User {

    class SetAgeMigration: Migration {

        typealias Database = MongoDatabase

        static func prepare(on conn: Database.Connection) -> Future<Void> {
            return User.query(on: conn).update(\.age, to: 99).run()
        }

        static func revert(on conn: Database.Connection) -> Future<Void> {
            return User.query(on: conn).update(\.age, to: nil).run()
        }
    }
}

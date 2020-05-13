//
//  Exports.swift
//  FluentMongo
//
//  Created by Dale Buckley on 13/05/2020.
//  Copyright © 2020 Asensei Inc. All rights reserved.
//

@_exported import FluentKit
@_exported import MongoSwift

extension DatabaseID {
    public static var mongo: DatabaseID {
        return .init(string: "mongo")
    }
}

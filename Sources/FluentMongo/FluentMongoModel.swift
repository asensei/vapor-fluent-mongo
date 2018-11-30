//
//  FluentMongoModel.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 06/12/2018.
//  Copyright © 2018 Asensei Inc. All rights reserved.
//

import Foundation
import Fluent

public protocol FluentMongoModel: Model where Database == MongoDatabase {
    var _id: ID? { get set }
}

public extension FluentMongoModel {
    public static var idKey: WritableKeyPath<Self, ID?> {
        return \._id
    }
}

//
//  FluentMongoModel.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 06/12/2018.
//  Copyright © 2018 Asensei Inc. All rights reserved.
//

import Foundation
import Fluent

public protocol FluentMongoModel {

    associatedtype ID: Fluent.ID

    var _id: ID? { get set }
}

extension FluentMongoModel where Self: Model {
    public static var idKey: WritableKeyPath<Self, ID?> {
        return \._id
    }
}

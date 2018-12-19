//
//  MongoDatabase+JoinSupporting.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 19/12/2018.
//  Copyright © 2018 Asensei Inc. All rights reserved.
//

import Foundation
import Fluent

extension MongoDatabase: JoinSupporting {

    public typealias QueryJoin = FluentMongoQueryJoin

    public typealias QueryJoinMethod = FluentMongoQueryJoinMethod
}

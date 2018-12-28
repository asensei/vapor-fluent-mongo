//
//  BSONCoder.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 28/12/2018.
//  Copyright © 2018 Asensei Inc. All rights reserved.
//

import Foundation
import MongoSwift

public protocol BSONCoder {

    static var encoder: BSONEncoder { get }

    static var decoder: BSONDecoder { get }
}

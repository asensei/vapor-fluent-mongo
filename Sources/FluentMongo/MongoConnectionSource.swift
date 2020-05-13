//
//  MongoConnectionSource.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 22/10/2019.
//  Copyright © 2019 Asensei Inc. All rights reserved.
//

import Foundation
import AsyncKit
import FluentKit

struct MongoConnectionSource: ConnectionPoolSource {
    
    // MARK: Initialization

    init(configuration: MongoConfiguration) {
        self.configuration = configuration
    }

    // MARK: Managing Connection Source

    private let configuration: MongoConfiguration

    // MARK: ConnectionPoolSource

    public func makeConnection(logger: Logger, on eventLoop: EventLoop) -> EventLoopFuture<Never> {

        fatalError()

//        return MongoConnection.connect(
//            to: self.configuration.connectionURL.absoluteString,
//            database: self.configuration.database,
//            options: self.configuration.options,
//            threadPool: threadPool,
//            on: eventLoop
//        )
    }
}

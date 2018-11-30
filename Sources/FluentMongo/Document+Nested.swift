//
//  Document+Nested.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 06/12/2018.
//  Copyright © 2018 Asensei Inc. All rights reserved.
//

import Foundation
import MongoSwift

// Review when https://jira.mongodb.org/browse/SWIFT-273 will be fixed.
public extension Document {
    public subscript(keys: [String]) -> BSONValue? {
        get {
            guard !keys.isEmpty else {
                return nil
            }

            var value: BSONValue? = self

            for key in keys {
                value = (value as? Document)?[key]
            }

            return value
        }
        set {
            func setNewValue(for keys: [String], in document: inout Document) {
                guard !keys.isEmpty else {
                    return
                }

                guard keys.count > 1 else {
                    document[keys[0]] = newValue

                    return
                }

                var path = keys
                let component = path.removeFirst()
                var next = document[component] as? Document ?? Document()
                setNewValue(for: path, in: &next)
                document[component] = next
            }

            setNewValue(for: keys, in: &self)
        }
    }

    public subscript(keys: String...) -> BSONValue? {
        get {
            return self[keys]
        }
        set {
            self[keys] = newValue
        }
    }
}

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
extension Document {
    public subscript(keys: [String]) -> BSON? {
        get {
            guard !keys.isEmpty else {
                return nil
            }

            var value: BSON? = .document(self)

            for key in keys {
                value = (value?.documentValue)?[key]
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
                var next = document[component]?.documentValue ?? Document()
                setNewValue(for: path, in: &next)
                document[component] = .document(next)
            }

            setNewValue(for: keys, in: &self)
        }
    }

    public subscript(keys: String...) -> BSON? {
        get {
            return self[keys]
        }
        set {
            self[keys] = newValue
        }
    }
}

extension Document {

    func byRemovingKeysPrefix(_ prefix: String) -> Document {

        func removeKeysPrefix(_ document: Document) -> Document {

            func ensureNoRootNameSpace(_ value: String) -> String {
                let components = value.components(separatedBy: ".")
                if components.first == prefix {
                    return components.dropFirst().joined(separator: ".")
                } else {
                    return value
                }
            }

            var mutableFilter = Document()

            for item in document {
                switch document[item.key] {
                case .document(let value):
                    mutableFilter[ensureNoRootNameSpace(item.key)] = .document(removeKeysPrefix(value))
                case .array(let value):
                    mutableFilter[ensureNoRootNameSpace(item.key)] = .array(value.map {
                        switch $0 {
                        case .document(let value):
                            return .document(removeKeysPrefix(value))
                        default:
                            return $0
                        }
                    })
                case .some(let value):
                    mutableFilter[ensureNoRootNameSpace(item.key)] = value
                case .none:
                    mutableFilter[ensureNoRootNameSpace(item.key)] = nil
                }
            }

            return mutableFilter
        }

        return removeKeysPrefix(self)
    }
}

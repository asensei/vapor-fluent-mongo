//
//  Fluent+Additions.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 12/06/2020.
//  Copyright © 2020 Asensei Inc. All rights reserved.
//

import Foundation
import FluentKit

extension DatabaseInput {

    public func setIfPresent(_ value: DatabaseQuery.Value?, at key: FieldKey) {
        guard let value = value else {
            return
        }

        self.set(value, at: key)
    }
}

extension DatabaseOutput {

    public func decodeIfPresent<T: Decodable>(_ key: FieldKey, as type: T.Type) throws -> T? {
        guard self.contains(key) else {
            return nil
        }

        return try self.decode(key, as: type)
    }
}

extension FieldProperty {

    public func output(from output: DatabaseOutput, defaultValue: Value) throws {
        if output.contains(self.key) {
            try self.output(from: output)
        } else {
            self.value = defaultValue
        }
    }
}

extension OptionalFieldProperty {

    public func output(from output: DatabaseOutput, defaultValue: Value) throws {
        if output.contains(self.key) {
            try self.output(from: output)
        } else {
            self.value = defaultValue
        }
    }
}

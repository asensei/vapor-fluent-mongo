//
//  FluentMongoQueryData.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 11/12/2018.
//  Copyright © 2018 Asensei Inc. All rights reserved.
//

import Foundation
import Fluent
import MongoSwift

// MARK: - QueryData

public typealias FluentMongoQueryData = Document

extension Database where Self: QuerySupporting, Self.Query == FluentMongoQuery, Self.QueryData == FluentMongoQueryData, Self.QueryField == FluentMongoQueryField {

    public static func queryDataSet<E: Encodable>(_ field: QueryField, to data: E, on query: inout Query) {
        let path = ["$set"] + field.path
        let value: BSONValue? = BSONEncoder().encode(data)
        var document = query.data ?? Document()
        document[path] = value
        query.data = document
    }
}

extension Database where Self: QuerySupporting, Self.Query == FluentMongoQuery, Self.QueryData == FluentMongoQueryData {

    public static func queryDataApply(_ data: QueryData, to query: inout Query) {
        query.data = data
    }
}

extension Database where Self: QuerySupporting, Self.Output == FluentMongoOutput {

    public static func queryDecode<D: Decodable>(_ output: Output, entity: String, as decodable: D.Type, on conn: Connection) -> Future<D> {
        do {
            return conn.future(try BSONDecoder().decode(D.self, from: output))
        } catch {
            return conn.future(error: error)
        }
    }
}

extension Database where Self: QuerySupporting, Self.QueryData == FluentMongoQueryData {

    public static func queryEncode<E: Encodable>(_ encodable: E, entity: String) throws -> QueryData {
        return try BSONEncoder().encode(encodable)
    }
}

// MARK: - QueryField

public typealias FluentMongoQueryField = FluentProperty

extension Database where Self: QuerySupporting, Self.QueryField == FluentProperty {

    public static func queryField(_ property: FluentProperty) -> QueryField {
        return property
    }
}

// MARL: - Output

public typealias FluentMongoOutput = Document

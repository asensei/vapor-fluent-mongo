//
//  MongoDatabaseOutputTests.swift
//  FluentMongoTests
//
//  Created by Dale Buckley on 18/05/2020.
//  Copyright © 2020 Asensei Inc. All rights reserved.
//

import XCTest
@testable import FluentMongo

final class MongoDatabaseOutputTests: XCTestCase {

    func testSchema() throws {

        let document = try Document(fromJSON: "{ \"key\": \"value\" }")
        let decoder = BSONDecoder()
        let output = document.databaseOutput(using: decoder)

        let newOutput = output.schema("newSchema")

        XCTAssertEqual(newOutput.description, output.description)
        XCTAssertTrue(type(of: newOutput) == type(of: output))
    }

    func testContains() throws {

        let document = try Document(fromJSON: """
            {
                "key": "value",
                "_id": "abc123",
                "aggregate_result": "abcd4567",
                "object1": {
                    "object2": {
                        "object3": {
                            "embeddedKey": "embeddedKey"
                        }
                    }
                }
            }
            """
        )
        let output = document.databaseOutput(using: BSONDecoder())

        XCTAssertTrue(output.contains("key"))
        XCTAssertTrue(output.contains(.string("key")))
        XCTAssertTrue(output.contains(.id))
        XCTAssertTrue(output.contains(.aggregate))
    }

    func testContainsFromSubscript() {

        var document = Document()
        document.key = "value"
        document._id = "abc123"
        document.aggregate_result = "abcd4567"
        document.object1 = BSON(dictionaryLiteral:("object2", BSON(dictionaryLiteral:("object3", BSON(dictionaryLiteral:("embeddedKey", "embeddedKey"))))))
        let output = document.databaseOutput(using: BSONDecoder())

        XCTAssertTrue(output.contains("key"))
        XCTAssertTrue(output.contains(.string("key")))
        XCTAssertTrue(output.contains(.id))
        XCTAssertTrue(output.contains(.aggregate))
    }

    func testDecodeSimpleType() throws {

        let document = try Document(fromJSON: """
            {
                "object": {
                    "key": "value"
                }
            }
            """
        )
        let output = document.databaseOutput(using: BSONDecoder())

        let simpleType: SimpleTestType = try output.decode("object")

        XCTAssertEqual(simpleType.key, "value")
    }

    func testMongoKey() {

        let elements: [FieldKey] = [.id, .aggregate, .string("a"), "b"]

        XCTAssertEqual(elements.mongoKeys.dotNotation, "_id.aggregate_result.a.b")
    }
}

extension MongoDatabaseOutputTests {

    struct SimpleTestType: Decodable {
        let key: String
    }
}

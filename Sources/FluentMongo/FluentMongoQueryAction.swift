//
//  FluentMongoQueryAction.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 11/12/2018.
//  Copyright © 2018 Asensei Inc. All rights reserved.
//

import Foundation
import Fluent

// MARK: - QueryAction

public enum FluentMongoQueryAction {
    case insert
    case find
    case update
    case delete
}

extension Database where Self: QuerySupporting, Self.QueryAction == FluentMongoQueryAction {

    public static var queryActionCreate: QueryAction {
        return .insert
    }

    public static var queryActionRead: QueryAction {
        return .find
    }

    public static var queryActionUpdate: QueryAction {
        return .update
    }

    public static var queryActionDelete: QueryAction {
        return .delete
    }

    public static func queryActionIsCreate(_ action: QueryAction) -> Bool {
        return action == .insert
    }
}

extension Database where Self: QuerySupporting, Self.Query == FluentMongoQuery, Self.QueryAction == FluentMongoQueryAction {

    public static func queryActionApply(_ action: QueryAction, to query: inout Query) {
        query.action = action
    }
}

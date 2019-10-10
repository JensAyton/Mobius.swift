// Copyright (c) 2019 Spotify AB.
//
// Licensed to the Apache Software Foundation (ASF) under one
// or more contributor license agreements.  See the NOTICE file
// distributed with this work for additional information
// regarding copyright ownership.  The ASF licenses this file
// to you under the Apache License, Version 2.0 (the
// "License"); you may not use this file except in compliance
// with the License.  You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import Foundation

/// Protocol for logging init and update calls.
public protocol MobiusLogger: LoopTypes {
    ///  Called right before the `Initiator` function is called.
    ///
    ///  This method mustn't block, as it'll hinder the loop from running. It will be called on the
    ///  same thread as the `Initiator` function.
    ///
    /// - Parameter model: the model that will be passed to the initiator function
    func willInitiate(model: Model)

    /// Called right after the `Initiator` function is called.
    ///
    /// This method mustn't block, as it'll hinder the loop from running. It will be called on the
    /// same thread as the initiator function.
    ///
    /// - Parameters:
    ///     - startModel: the model that was passed to the initiator
    ///     - initiatedModel: the model after the initiator was run
    ///     - effects: the effects returned by the initator
    func didInitiate(startModel: Model, initiatedModel: Model, effects: [Effect])

    /// Old variant of `didInitiate`. Implement the signature above instead.
    ///
    /// This method mustn't block, as it'll hinder the loop from running. It will be called on the
    /// same thread as the initiator function.
    ///
    /// - Parameters:
    ///     - model: the model that was passed to the initiator
    ///     - first: the resulting `First` instance
    func didInitiate(model: Model, first: First<Model, Effect>)

    /// Called right before the `Update` function is called.
    ///
    /// This method mustn't block, as it'll hinder the loop from running. It will be called on the
    /// same thread as the update function.
    ///
    /// - Parameters:
    ///     - model: the model that will be passed to the update function
    ///     - event: the event that will be passed to the update function
    func willUpdate(model: Model, event: Event)

    /// Called right after the `Update` function is called.
    ///
    /// This method mustn't block, as it'll hinder the loop from running. It will be called on the
    /// same thread as the update function.
    ///
    /// - Parameters:
    ///     - model: the model that was passed to update
    ///     - event: the event that was passed to update
    ///     - result: the `Next` that update returned
    func didUpdate(inputModel: Model, event: Event, outputModel: Model, effects: [Effect])

    /// Old variant of `didUpdate`. Implement the signature above instead.
    ///
    /// This method mustn't block, as it'll hinder the loop from running. It will be called on the
    /// same thread as the update function.
    ///
    /// - Parameters:
    ///     - model: the model that was passed to update
    ///     - event: the event that was passed to update
    ///     - result: the `Next` that update returned
    func didUpdate(model: Model, event: Event, next: Next<Model, Effect>)
}

/// Default implementations do nothing
public extension MobiusLogger {
    func willInitiate(model: Model) {}

    func didInitiate(startModel: Model, initiatedModel: Model, effects: [Effect]) {
        // Default implementation calls old signature to support old loggers
        didInitiate(model: startModel, first: First(model: initiatedModel, effects: Set(effects)))
    }

    func didInitiate(model: Model, first: First<Model, Effect>) {}

    func willUpdate(model: Model, event: Event) {}

    func didUpdate(inputModel: Model, event: Event, outputModel: Model, effects: [Effect]) {
        // Default implementation calls old signature to support old loggers
        didUpdate(model: inputModel, event: event, next: .next(outputModel, effects: Set(effects)))
    }

    func didUpdate(model: Model, event: Event, next: Next<Model, Effect>) {}
}

class NoopLogger<Types: LoopTypes>: MobiusLogger {
    typealias Model = Types.Model
    typealias Event = Types.Event
    typealias Effect = Types.Effect
}

/// Type-erased `MobiusLogger`.
public class AnyMobiusLogger<Types: LoopTypes>: MobiusLogger {
    public typealias Model = Types.Model
    public typealias Event = Types.Event
    public typealias Effect = Types.Effect

    private let willInitiateClosure: (Model) -> Void
    private let didInitiateClosure: (Model, Model, [Effect]) -> Void
    private let willUpdateClosure: (Model, Event) -> Void
    private let didUpdateClosure: (Model, Event, Model, [Effect]) -> Void

    public init<L: MobiusLogger>(_ base: L) where L.Model == Model, L.Event == Event, L.Effect == Effect {
        willInitiateClosure = base.willInitiate
        didInitiateClosure = base.didInitiate
        willUpdateClosure = base.willUpdate
        didUpdateClosure = base.didUpdate
    }

    public func willInitiate(model: Model) {
        willInitiateClosure(model)
    }

    public func didInitiate(startModel: Model, initiatedModel: Model, effects: [Effect]) {
        didInitiateClosure(startModel, initiatedModel, effects)
    }

    public func willUpdate(model: Model, event: Event) {
        willUpdateClosure(model, event)
    }

    public func didUpdate(inputModel: Model, event: Event, outputModel: Model, effects: [Effect]) {
        didUpdateClosure(inputModel, event, outputModel, effects)
    }
}

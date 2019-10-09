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

public protocol LoopTypes {
    associatedtype Model
    associatedtype Event
    associatedtype Effect: Hashable
}

public typealias _NewUpdate<T: LoopTypes> = (inout T.Model, T.Event) -> [T.Effect]

public typealias _NewInitiator<T: LoopTypes> = (inout T.Model) -> [T.Effect]

public enum Mobius {}

// MARK: - Building a Mobius Loop

public extension Mobius {
    /// Create a `Builder` to help you configure a `MobiusLoop ` before starting it.
    ///
    /// The builder is immutable. When setting various properties, a new instance of a builder will be returned.
    /// It is therefore recommended to chain the loop configuration functions
    ///
    /// Once done configuring the loop you can start the loop using `start(from:)`.
    ///
    /// - Parameters:
    ///   - update: the `Update` function of the loop
    ///   - effectHandler: an instance conforming to the `ConnectableProtocol`. Will be used to handle effects by the loop
    /// - Returns: a `Builder` instance that you can further configure before starting the loop
    @available(*, deprecated, message: "use new update signature (inout Model, Event) -> [Effect]")
    static func loop<T: LoopTypes, C: Connectable>(update: @escaping _OldUpdate<T>, effectHandler: C) -> Builder<T> where C.InputType == T.Effect, C.OutputType == T.Event {
        return loop(update: Mobius._adaptUpdate(update), effectHandler: effectHandler)
    }

    /// Create a `Builder` to help you configure a `MobiusLoop ` before starting it.
    ///
    /// The builder is immutable. When setting various properties, a new instance of a builder will be returned.
    /// It is therefore recommended to chain the loop configuration functions
    ///
    /// Once done configuring the loop you can start the loop using `start(from:)`.
    ///
    /// - Parameters:
    ///   - update: the `Update` function of the loop
    ///   - effectHandler: an instance conforming to the `ConnectableProtocol`. Will be used to handle effects by the loop
    /// - Returns: a `Builder` instance that you can further configure before starting the loop
    static func loop<T: LoopTypes, C: Connectable>(update: @escaping _NewUpdate<T>, effectHandler: C) -> Builder<T> where C.InputType == T.Effect, C.OutputType == T.Event {
        return Builder<T>(
            update: update,
            effectHandler: effectHandler,
            initiator: { _ in [] },
            eventSource: AnyEventSource<T.Event>({ _ in AnonymousDisposable(disposer: {}) }),
            eventQueue: DispatchQueue(label: "event processor"),
            effectQueue: DispatchQueue(label: "effect processor", attributes: .concurrent),
            logger: AnyMobiusLogger(NoopLogger<T>())
        )
    }

    struct Builder<Types: LoopTypes> {
        private let update: _NewUpdate<Types>
        private let effectHandler: AnyConnectable<Types.Effect, Types.Event>
        private let initiator: _NewInitiator<Types>
        private let eventSource: AnyEventSource<Types.Event>
        private let eventQueue: DispatchQueue
        private let effectQueue: DispatchQueue
        private let logger: AnyMobiusLogger<Types>

        fileprivate init<C: Connectable>(
            update: @escaping _NewUpdate<Types>,
            effectHandler: C,
            initiator: @escaping _NewInitiator<Types>,
            eventSource: AnyEventSource<Types.Event>,
            eventQueue: DispatchQueue,
            effectQueue: DispatchQueue,
            logger: AnyMobiusLogger<Types>
        ) where C.InputType == Types.Effect, C.OutputType == Types.Event {
            self.update = update
            self.effectHandler = AnyConnectable(effectHandler)
            self.initiator = initiator
            self.eventSource = eventSource
            self.eventQueue = eventQueue
            self.effectQueue = effectQueue
            self.logger = logger
        }

        public func withEventSource<ES: EventSource>(_ eventSource: ES) -> Builder<Types> where ES.Event == Types.Event {
            return Builder<Types>(
                update: update,
                effectHandler: effectHandler,
                initiator: initiator,
                eventSource: AnyEventSource(eventSource),
                eventQueue: eventQueue,
                effectQueue: effectQueue,
                logger: logger
            )
        }

        @available(*, deprecated, message: "use new initiator signature (Model) -> (Model, [Effect])")
        public func withInitiator(_ initiator: @escaping _OldInitiator<Types>) -> Builder<Types> {
            return withInitiator(Mobius._adaptInitiator(initiator))
        }

        public func withInitiator(_ initiator: @escaping _NewInitiator<Types>) -> Builder<Types> {
            return Builder<Types>(
                update: update,
                effectHandler: effectHandler,
                initiator: initiator,
                eventSource: eventSource,
                eventQueue: eventQueue,
                effectQueue: effectQueue,
                logger: logger
            )
        }

        public func withEventQueue(_ eventQueue: DispatchQueue) -> Builder<Types> {
            return Builder<Types>(
                update: update,
                effectHandler: effectHandler,
                initiator: initiator,
                eventSource: eventSource,
                eventQueue: eventQueue,
                effectQueue: effectQueue,
                logger: logger
            )
        }

        public func withEffectQueue(_ effectQueue: DispatchQueue) -> Builder<Types> {
            return Builder<Types>(
                update: update,
                effectHandler: effectHandler,
                initiator: initiator,
                eventSource: eventSource,
                eventQueue: eventQueue,
                effectQueue: effectQueue,
                logger: logger
            )
        }

        public func withLogger<L: MobiusLogger>(_ logger: L) -> Builder<Types> where L.Model == Types.Model, L.Event == Types.Event, L.Effect == Types.Effect {
            return Builder<Types>(
                update: update,
                effectHandler: effectHandler,
                initiator: initiator,
                eventSource: eventSource,
                eventQueue: eventQueue,
                effectQueue: effectQueue,
                logger: AnyMobiusLogger(logger)
            )
        }

        public func start(from initialModel: Types.Model) -> MobiusLoop<Types> {
            return MobiusLoop.createLoop(
                update: update,
                effectHandler: effectHandler,
                initialModel: initialModel,
                initiator: initiator,
                eventSource: eventSource,
                eventQueue: eventQueue,
                effectQueue: effectQueue,
                logger: logger
            )
        }
    }
}

extension Mobius {

    static func apply<Model, Event, Effect>(
        _ update: (inout Model, Event) -> [Effect],
        model: Model,
        event: Event
    ) -> (Model, [Effect]) {
        var newModel = model
        let effects = update(&newModel, event)
        return (newModel, effects)
    }

    static func apply<Model, Effect>(_ initiator: (inout Model) -> Effect, model: Model) -> (Model, Effect) {
        var newModel = model
        let effects = initiator(&newModel)
        return (newModel, effects)
    }
}

class LoggingInitiator<Types: LoopTypes> {
    private let realInit: _NewInitiator<Types>
    private let willInit: (Types.Model) -> Void
    private let didInit: (Types.Model, First<Types.Model, Types.Effect>) -> Void

    init<L: MobiusLogger>(_ realInit: @escaping _NewInitiator<Types>, _ logger: L) where L.Model == Types.Model, L.Event == Types.Event, L.Effect == Types.Effect {
        self.realInit = realInit
        willInit = logger.willInitiate
        didInit = logger.didInitiate
    }

    func initiate(_ model: inout Types.Model) -> [Types.Effect] {
        let oldModel = model

        willInit(model)
        let effects = realInit(&model)
        didInit(oldModel, First(model: model, effects: Set(effects)))

        return effects
    }
}

class LoggingUpdate<Types: LoopTypes> {
    private let realUpdate: _NewUpdate<Types>
    private let willUpdate: (Types.Model, Types.Event) -> Void
    private let didUpdate: (Types.Model, Types.Event, Next<Types.Model, Types.Effect>) -> Void

    init<L: MobiusLogger>(_ realUpdate: @escaping _NewUpdate<Types>, _ logger: L) where L.Model == Types.Model, L.Event == Types.Event, L.Effect == Types.Effect {
        self.realUpdate = realUpdate
        willUpdate = logger.willUpdate
        didUpdate = logger.didUpdate
    }

    func update(_ model: inout Types.Model, _ event: Types.Event) -> [Types.Effect] {
        let oldModel = model

        willUpdate(model, event)
        let effects = realUpdate(&model, event)
        didUpdate(oldModel, event, .next(model, effects: Set(effects)))

        return effects
    }
}

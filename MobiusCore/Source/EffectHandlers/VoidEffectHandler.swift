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


/// The `VoidEffectHandler` protocol enables cleaner effect handlers for effects with no parameters.
///
/// Implementation note: this was originally implemented as a protocol conforming to `EffectHandler`, but the type
/// checker found this confusing.
public protocol VoidEffectHandler {
    associatedtype Effect
    associatedtype Event

    func match(effect: Effect) -> Bool
    func run(sendEvent: @escaping (Event) -> Void)
    func stop()
}

public extension VoidEffectHandler {
    func stop() {}
}

public extension AnyEffectHandler {
    init<Handler: VoidEffectHandler>(_ handler: Handler)
    where Handler.Effect == Effect, Handler.Event == Event {
        self.init(
            debugIdentity: handler,
            match: { handler.match(effect: $0) ? () : nil },
            run: { _, sendEvent in handler.run(sendEvent: sendEvent) },
            stop: handler.stop
        )
    }
}

public extension CompositeEffectHandler {
    @discardableResult
    func addHandler<Handler: VoidEffectHandler>(_ handler: Handler)
    -> CompositeEffectHandler<Types> where Handler.Effect == Effect, Handler.Event == Event {
        return addHandler(AnyEffectHandler(handler))
    }
}

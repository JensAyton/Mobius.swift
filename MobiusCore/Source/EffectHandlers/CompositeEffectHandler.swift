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


/// A collection of `EffectHandler`s with the same `Effect` and `Event` types, but arbitrary `EffectPayload` types.
///
/// - Invariant: At most one child effect handler may match any particular effect. Additionally, the Mobius loop will
/// require that at _least_ one child effect handler matches.
public final class CompositeEffectHandler<Types: LoopTypes>: EffectHandler {
    public typealias Effect = Types.Effect
    public typealias Event = Types.Event
    public typealias EffectPayload = _SuspendedHandler<Event>

    private var childHandlers: [AnyEffectHandler<Effect, Event>] = []

    public init() {}

    /// Add a sub-handler to this effect handler.
    ///
    /// - Parameters:
    ///   - handler: An effect handler with the appropriate `Effect` and `Event` types.
    /// - Returns: The `CompositeEffectHandler`, for chaining.
    @discardableResult
    public func addHandler<Handler: EffectHandler>(_ handler: Handler)
    -> CompositeEffectHandler<Types> where Handler.Effect == Effect, Handler.Event == Event
    {
        childHandlers.append(AnyEffectHandler(handler))
        return self
    }

    public func match(effect: Effect) -> _SuspendedHandler<Event>? {
        let matching = childHandlers.compactMap { $0.match(effect: effect) }

        switch matching.count {
        case 0:
            return nil
        case 1:
            return matching[0]
        default:
            #if DEBUG
            let matchDescriptions = String(reflecting: matching.map { $0.debugIdentity })
            MobiusHooks.onError("More than one effect handler is handling the effect: \(effect) - \(matchDescriptions))")
            #else
            MobiusHooks.onError("More than one effect handler is handling the effect: \(effect)")
            #endif
            return nil
        }
    }

    public func run(with match: _SuspendedHandler<Event>, sendEvent: @escaping(Event) -> Void) {
        match.run(sendEvent)
    }

    public func stop() {
        childHandlers.forEach { $0.stop() }
    }
}


#if DEBUG

extension CompositeEffectHandler: CustomReflectable {
    public var customMirror: Mirror {
        return Mirror(self, children: ["childHandlers": childHandlers.map { $0.debugIdentity }], displayStyle: .struct)
    }
}

#endif

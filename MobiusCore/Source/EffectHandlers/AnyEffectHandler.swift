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


/// `EffectHandler` with `EffectPayload` erased. This can homogenize all event handlers for a given `LoopTypes`.
public struct AnyEffectHandler<Effect, Event>: EffectHandler {
    public typealias EffectPayload = _SuspendedHandler<Event>

    #if DEBUG
    let debugIdentity: Any   // The handler, used solely to provide better reflection in debugging builds.
    #endif
    private let matchClosure: (Effect) -> _SuspendedHandler<Event>?
    private let stopClosure: () -> Void

    public init<Handler: EffectHandler>(_ handler: Handler)
    where Handler.Effect == Effect, Handler.Event == Event {
        self.init(
            debugIdentity: handler, match:
            handler.match,
            run: handler.run,
            stop: handler.stop
        )
    }

    internal init<Payload>(
        debugIdentity: Any,
        match: @escaping (Effect) -> Payload?,
        run: @escaping (Payload, @escaping (Event) -> Void) -> Void,
        stop: @escaping () -> Void
    ) {
        #if DEBUG
        self.debugIdentity = debugIdentity
        #endif

        matchClosure = { effect in
            match(effect).map { payload in
                return _SuspendedHandler(debugIdentity: debugIdentity) {
                    run(payload, $0)
                }
            }
        }
        stopClosure = stop
    }

    public func match(effect: Effect) -> _SuspendedHandler<Event>? {
        return matchClosure(effect)
    }

    public func run(with suspended: _SuspendedHandler<Event>, sendEvent: @escaping (Event) -> Void) {
        suspended.run(sendEvent)
    }

    public func stop() {
        stopClosure()
    }
}


/// `_SuspendedHandler` is an implementation detail that has to be exposed for fun type system reasons.
///
/// This is essentially an `((Event) -> Void) -> Void` with a string attached in debug builds. It represents a handler
/// whose match has passed, bound to a payload. Calling `.run()` will run the handler.
///
/// The point is to erase the specific `EffectPayload`, but we ended up erasing the `Effect` too.
public struct _SuspendedHandler<Event> {
    #if DEBUG
    public let debugIdentity: Any
    #endif

    internal let run: (@escaping (Event) -> Void) -> Void

    init(debugIdentity: Any, run: @escaping (@escaping (Event) -> Void) -> Void) {
        #if DEBUG
        self.debugIdentity = debugIdentity
        #endif
        self.run = run
    }
}


#if DEBUG

extension AnyEffectHandler: CustomReflectable {
    public var customMirror: Mirror {
        return Mirror(self, children: ["handler": debugIdentity], displayStyle: .struct)
    }
}

extension _SuspendedHandler: CustomReflectable {
    public var customMirror: Mirror {
        return Mirror(self, children: ["handler": debugIdentity], displayStyle: .struct)
    }
}

#endif

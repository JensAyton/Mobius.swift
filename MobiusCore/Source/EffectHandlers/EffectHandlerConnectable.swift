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


public final class EffectHandlerConnectable<Handler: EffectHandler>: Connectable {
    private let effectHandler: Handler
    private var connected: Bool = false

    public init(effectHandler: Handler) {
        self.effectHandler = effectHandler
    }

    public func connect(_ consumer: @escaping (Handler.Event) -> Void) -> Connection<Handler.Effect> {
        guard !connected else {
            MobiusHooks.onError("Effect handler only supports connecting one loop")
            return BrokenConnection<Handler.Effect>.connection()
        }

        var cancelled = false
        let cancellableConsumer: (Handler.Event) -> Void = {
            if !cancelled {
                consumer($0)
            }
        }

        let effectHandler = self.effectHandler
        connected = true

        return Connection<Handler.Effect>(
            acceptClosure: { effect in
                guard let match = effectHandler.match(effect: effect) else {
                    MobiusHooks.onError("No effect handler is handling the effect: \(effect)")
                    return
                }
                effectHandler.run(with: match, sendEvent: cancellableConsumer)
            },
            disposeClosure: { [weak self] in
                cancelled = true
                effectHandler.stop()
                self?.connected = false
            }
        )
    }
}

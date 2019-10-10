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

@available(*, deprecated, message: "use Update instead")
public typealias _OldUpdate<T: LoopTypes> = (T.Model, T.Event) -> Next<T.Model, T.Effect>

@available(*, deprecated, message: "use Initiator instead")
public typealias _OldInitiator<T: LoopTypes> = (T.Model) -> First<T.Model, T.Effect>

/**
 Helpers to convert old-style update and initiator functions (`_OldUpdate` and `_OldInitiator`) to new-style ones
 (`Update` and `Initiator`). These are exposed for use in MobiusTest; they’re not intended for use by client code,
 except perhaps transitionally, and will be removed.
 */
public extension Mobius {

    /// Convert an old-style `Update` to a new-style one
    static func _adaptUpdate<Model, Event, Effect>(_ update: @escaping (Model, Event) -> Next<Model, Effect>)
    -> (inout Model, Event) -> [Effect] {
        return { model, event in
            let next = update(model, event)
            if let newModel = next.model {
                model = newModel
            }
            return Array(next.effects)
        }
    }

    /// Convert a new-style `Initiator` to an old-style one
    static func _adaptInitiator<Model, Effect>(_ initiator: @escaping (Model) -> First<Model, Effect>)
    -> (inout Model) -> [Effect] {
        return { model in
            let first = initiator(model)
            model = first.model
            return Array(first.effects)
        }
    }
}


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
import MobiusCore

public class ConsoleLogger<Types: LoopTypes>: MobiusLogger {
    public typealias Model = Types.Model
    public typealias Event = Types.Event
    public typealias Effect = Types.Effect

    private let prefix: String

    public init(tag: String = "Mobius") {
        prefix = tag + ": "
    }

    public func willInitiate(model: Model) {
        print(prefix + "Initializing loop")
    }

    public func didInitiate(startModel: Model, initiatedModel: Model, effects: [Effect]) {
        print(prefix + "Loop initialized, starting from model: \(initiatedModel)")

        effects.forEach { effect in
            print(prefix + "Effect dispatched: \(effect)")
        }
    }

    public func willUpdate(model: Model, event: Event) {
        print(prefix + "Event received: \(event)")
    }

    public func didUpdate(inputModel: Model, event: Event, outputModel: Model, effects: [Effect]) {
        print(prefix + "Model updated: \(outputModel)")

        effects.forEach { effect in
            print(prefix + "Effect dispatched: \(effect)")
        }
    }
}

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

import MobiusCore

public typealias AssertFirst<Model, Effect: Hashable> = (First<Model, Effect>) -> Void

public final class InitSpec<Types: LoopTypes> {
    let initiator: _NewInitiator<Types>

    @available(*, deprecated, message: "use new initiator signature (Model) -> (Model, [Effect])")
    public init(_ initiator: @escaping _OldInitiator<Types>) {
        self.initiator = Mobius._adaptInitiator(initiator)
    }

    public init(_ initiator: @escaping _NewInitiator<Types>) {
        self.initiator = initiator
    }

    public func when(_ model: Types.Model) -> Then {
        return Then(model, initiator: initiator)
    }

    public struct Then {
        let model: Types.Model
        let initiator: _NewInitiator<Types>

        // Migration note: unlike the UpdateSpec equivalents, this is public for some reason.
        @available(*, deprecated, message: "use new initiator signature (Model) -> (Model, [Effect])")
        public init(_ model: Types.Model, initiator: @escaping _OldInitiator<Types>) {
            self.model = model
            self.initiator = Mobius._adaptInitiator(initiator)
        }

        public init(_ model: Types.Model, initiator: @escaping _NewInitiator<Types>) {
            self.model = model
            self.initiator = initiator
        }

        public func then(_ assertion: AssertFirst<Types.Model, Types.Effect>) {
            var newModel = model
            let effects = initiator(&newModel)
            assertion(First(model: newModel, effects: Set(effects)))
        }
    }
}

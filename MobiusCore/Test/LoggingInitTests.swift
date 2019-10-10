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

@testable import MobiusCore
import Nimble
import Quick

class LoggingInitiatorTests: QuickSpec {
    override func spec() {
        describe("LoggingInitiator") {
            var logger: TestMobiusLogger!
            var loggingInitiator: LoggingInitiator<AllStrings>!

            beforeEach {
                logger = TestMobiusLogger()
                loggingInitiator = LoggingInitiator({ _ in [] }, logger)
            }

            it("should log willInitiate and didInitiate for each initiate attempt") {
                _ = Mobius.apply(loggingInitiator.initiate, model: "from this")

                expect(logger.logMessages).to(equal(["willInitiate(from this)", "didInitiate(from this, First<String, String>(model: \"from this\", effects: Set([])))"]))
            }

            it("should return init from delegate") {
                var model = "hey"
                let effects = loggingInitiator.initiate(&model)

                expect(model).to(equal("hey"))
                expect(effects).to(beEmpty())
            }
        }
    }
}

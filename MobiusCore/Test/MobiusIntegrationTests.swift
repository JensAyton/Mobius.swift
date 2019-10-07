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
import MobiusCore // not using '@testable', because we should only use public APIs in these tests
import Nimble
import Quick

// Should only test public APIs
class MobiusIntegrationTests: QuickSpec {
    // swiftlint:disable function_body_length
    override func spec() {
        describe("Mobius integration tests") {
            struct TestLogic: LoopTypes {
                typealias Model = String
                typealias Event = String
                typealias Effect = String

                func initiate(model: inout Model) -> [Effect] {
                    switch model {
                    case "start":
                        model = "init"
                        return ["trigger loading"]
                    default:
                        fatalError("unexpected model \(model)")
                    }
                }

                func update(model: inout Model, event: Event) -> [Effect] {
                    switch event {
                        case "button pushed":
                            model = "pushed"
                            return []
                        case "trigger effect":
                            model = "triggered"
                            return ["leads to event"]
                        case "effect feedback":
                            model = "done"
                            return []
                        case "from source":
                            model = "event sourced"
                            return []
                        default:
                            fatalError("unexpected event \(event)")
                    }
                }
            }

            var receivedModels: [String]!
            var builder: Mobius.Builder<TestLogic>!
            var loop: MobiusLoop<TestLogic>!
            var queue: DispatchQueue!

            var eventSourceEventConsumer: Consumer<String>!
            var modelConsumer: Consumer<String>!
            var receivedEffects: Recorder<String>!

            beforeEach {
                receivedModels = []
                modelConsumer = { model in
                    receivedModels.append(model)
                }

                let logic = TestLogic()
                queue = DispatchQueue.testQueue("test event queue")

                let effectHandler = IntegrationTestEffectHandler()
                receivedEffects = effectHandler.recorder

                let subscribe = { (consumer: @escaping Consumer<String>) -> Disposable in
                    eventSourceEventConsumer = consumer
                    return TestDisposable()
                }

                builder = Mobius.loop(update: logic.update, effectHandler: effectHandler)
                    .withInitiator(logic.initiate)
                    .withEventSource(AnyEventSource<String>(subscribe))
                    .withEventQueue(queue)
                    .withEffectQueue(queue)
            }

            afterEach {
                loop.dispose()
                loop = nil
            }

            context("given the loop isn't started") {
                it("should call initiate on start") {
                    loop = builder.start(from: "start")

                    loop.addObserver(modelConsumer)

                    queue.waitForOutstandingTasks()
                    expect(receivedModels).to(equal(["init"]))
                    expect(receivedEffects.items).to(equal(["trigger loading"]))
                }
            }

            context("given the loop is started") {
                beforeEach {
                    loop = builder.start(from: "start")
                    loop.addObserver(modelConsumer)

                    // clear out startup noise
                    queue.waitForOutstandingTasks() // Wait for the serial queue before clearing effects
                    receivedModels.removeAll()
                    receivedEffects.items.removeAll()
                }

                it("should be possible for the UI to push events and receive models") {
                    loop.dispatchEvent("button pushed")

                    queue.waitForOutstandingTasks()
                    expect(receivedModels).to(equal(["pushed"]))
                }

                it("should be possible for effect handler to receive effects and send events") {
                    loop.dispatchEvent("trigger effect")

                    queue.waitForOutstandingTasks()
                    expect(receivedModels).toEventually(equal(["triggered", "done"]))
                    expect(receivedEffects.items).to(equal(["leads to event"]))
                }

                it("should be possible for event sources to send events") {
                    eventSourceEventConsumer("from source")

                    queue.waitForOutstandingTasks()
                    expect(receivedModels).to(equal(["event sourced"]))
                }
            }
        }
    }
}

private class IntegrationTestEffectHandler: RecordingTestConnectable {
    override func accept(_ value: String) {
        super.accept(value)
        switch value {
        case "leads to event":
            consumer?("effect feedback")
        case "trigger loading":
            break
        default:
            fail("unexpected effect \(value)")
        }
    }
}

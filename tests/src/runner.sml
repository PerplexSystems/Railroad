(*
  Copyright 2023 Perplex Systems

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*)

structure TestRunner =
struct
  val tests =
    let
      open Test
      open Runner
      open TestHelper
    in
      describe "Runner"
        [ describe "fromTest"
            [ test "focus inside a focus has no effect" (fn _ =>
                let
                  val tests = describe "three tests"
                    [ test "passes" expectPass
                    , focus (describe "two tests"
                        [ test "fails" (fn _ => Expect.fail "failed on purpose")
                        , focus (test "is an only" (fn _ =>
                            Expect.fail "failed on purpose"))
                        ])
                    ]

                  val runners = fromTest tests
                  val expected = 2
                  val actual =
                    case runners of
                      Focusing rs => List.length rs
                    | _ => 0
                in
                  (Expect.equalFmt Int.compare Int.toString expected actual)
                end)

            , test "a skip inside a focus takes effect" (fn _ =>
                let
                  val tests = describe "three tests"
                    [ test "passes" expectPass
                    , focus (describe "two tests"
                        [ test "fails" (fn _ => Expect.fail "failed on purpose")
                        , skip (test "is skipped" (fn _ =>
                            Expect.fail "failed on purpose"))
                        ])
                    ]

                  val runners = fromTest tests
                  val expected = 1
                  val actual =
                    case runners of
                      Focusing rs => List.length rs
                    | _ => 0
                in
                  (Expect.equalFmt Int.compare Int.toString expected actual)
                end)

            , test "a focus inside a skip has no effect" (fn _ =>
                let
                  val tests = describe "three tests"
                    [ test "passes" expectPass
                    , skip (describe "two tests"
                        [ test "fails" (fn _ => Expect.fail "failed on purpose")
                        , focus (test "is skipped" (fn _ =>
                            Expect.fail "failed on purpose"))
                        ])
                    ]

                  val runners = fromTest tests
                  val expected = 1
                  val actual =
                    case runners of
                      Skipping rs => List.length rs
                    | _ => 0
                in
                  (Expect.equalFmt Int.compare Int.toString expected actual)
                end)
            ]
        , describe "todistribution"
            [ test "have a single test" (fn _ =>
                let
                  val tests = describe "single test"
                    [test "" (fn _ => Expectation.Pass)]
                  val distribution = todistribution tests
                  val expected = 1
                  val actual = List.length (#all distribution)
                in
                  Expect.equalFmt Int.compare Int.toString expected actual
                end)
            , test "have a focused test" (fn _ =>
                let
                  val tests = describe "single test"
                    [ focus (test "" (fn _ => Expectation.Pass))
                    , test "" (fn _ => Expectation.Pass)
                    ]
                  val distribution = todistribution tests
                  val actual = List.length (#focused distribution)
                in
                  Expect.equalFmt Int.compare Int.toString 1 actual
                end)
            ]
        ]
    end
end

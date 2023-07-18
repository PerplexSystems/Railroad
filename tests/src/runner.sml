structure TestRunner =
struct
  val tests =
    let
      open Test
      open Runner
      open TestHelper
    in
      describe "Runner"
        [ describe "fromtest"
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

                  val runners = fromtest tests
                  val expected = 2
                  val actual =
                    case runners of
                      Focusing rs => List.length rs
                    | _ => 0
                in
                  (Expect.equalfmt Int.compare Int.toString expected actual)
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

                  val runners = fromtest tests
                  val expected = 1
                  val actual =
                    case runners of
                      Focusing rs => List.length rs
                    | _ => 0
                in
                  (Expect.equalfmt Int.compare Int.toString expected actual)
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

                  val runners = fromtest tests
                  val expected = 1
                  val actual =
                    case runners of
                      Skipping rs => List.length rs
                    | _ => 0
                in
                  (Expect.equalfmt Int.compare Int.toString expected actual)
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
                  Expect.equalfmt Int.compare Int.toString expected actual
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
                  Expect.equalfmt Int.compare Int.toString 1 actual
                end)
            ]
        ]
    end
end

val runnerTests = Test.describe "Runner"
  [
    (* Test.describe "fromTest"
      [Test.test "focus inside focus has no effect" (fn _ =>
         let
           val tests = Test.describe "three tests"
             [ Test.test "passes" expectPass
             , Test.focus (Test.describe "two tests"
                 [ Test.test "fails" (fn _ => Expect.fail "failed on purpose")
                 , Test.focus (Test.test "is an only" (fn _ =>
                     Expect.fail "failed on purpose"))
                 ])
             ]

           val runners = Runner.fromTest tests
           val actual = List.length runners
           val expected = 2
         in
           (Expect.equal Int.compare expected actual)
         end)]
  ,
    Test.describe "distributeSeeds"
      [ Test.test "have a single test" (fn _ =>
          let
            val tests = Test.describe "single test"
              [Test.test "" (fn _ => Expectation.Pass)]
            val distribution = Runner.toDistribution tests
            val expected = 1
            val actual = List.length (#all distribution)
          in
            Expect.equal Int.compare expected actual
          end)
      ,
        Test.test "have a focused test" (fn _ =>
          let
            val tests = Test.describe "single test"
              [ Test.focus (Test.test "" (fn _ => Expectation.Pass))
              , Test.test "" (fn _ => Expectation.Pass)
              ]
            val distribution = Runner.toDistribution tests
            val actual = List.length (#focused distribution)
          in
            Expect.equal Int.compare 1 actual
          end)
      ] *)
  ]

val runnerTests =
  Test.describe "Runner" [

    Test.describe "distributeSeeds" [
      Test.test "have a single test" (fn _ =>
        let
          val tests =
            Test.describe "single test" [
              Test.test "" (fn _ => Expectation.Pass)
            ]
          val distribution = Runner.toDistribution tests
          val actual = List.length (#all distribution)
        in
          Expect.equal actual 1 Int.compare
        end
      ),

      Test.test "have a focused test" (fn _ =>
        let
          val tests =
            Test.describe "single test" [
              Test.focus (Test.test "" (fn _ => Expectation.Pass)),
              Test.test "" (fn _ => Expectation.Pass)
            ]
          val distribution = Runner.toDistribution tests
          val actual = List.length (#focused distribution)
        in
          Expect.equal actual 1 Int.compare
        end
      )
    ]
  ]

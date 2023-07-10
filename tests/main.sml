val _ =
  let
    val tests =
      Test.describe "test list" [
        Test.test "first test" (fn _ => (print ("hello from first test\n"); Expectation.Pass))
      ]
  in
    Runner.run tests
  end

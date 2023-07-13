fun expectPass _ = Expectation.Pass

val passingTest = Test.test "a passing test" expectPass

fun expectToFail expectation =
  case expectation of
    Expectation.Pass => Expect.fail "Expected test to fail, but it passed"
  | Expectation.Fail _ => Expect.pass

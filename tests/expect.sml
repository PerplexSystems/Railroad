val expectTests =
  Test.describe "Expect" [
    Test.test "Expect.equal" (fn _ =>
      Expect.equal 1 1 Int.compare),

    Test.test "Expect.less" (fn _ =>
      Expect.less 1 2 Int.compare),

    Test.test "Expect.greater" (fn _ =>
      Expect.greater 2 1 Int.compare)
  ]

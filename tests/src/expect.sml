structure TestExpect =
struct
  open Expect

  val tests =
    let
      open Test
      open TestHelper
    in
      describe "Expect"
        [ test "pass" (fn _ => Expect.pass)
        , test "fail" (fn _ =>
            expectToFail (Expect.fail "This test should fail"))
        , test "onFail" (fn _ =>
            expectToFail
              (Expect.onFail "This test should fail" (Expect.fail "custom fail")))
        , test "isTrue" (fn _ => Expect.isTrue true)
        , test "isFalse" (fn _ => Expect.isFalse false)
        , test "equal" (fn _ => Expect.equal Int.compare 1 1)
        , test "equalFmt" (fn _ => Expect.equalFmt Int.compare Int.toString 1 1)
        , test "notEqual" (fn _ => Expect.notEqual Int.compare 1 2)
        , test "notEqualFmt" (fn _ => Expect.notEqual Int.compare 1 2)
        , describe "atMost"
            [ test "equal value" (fn _ => Expect.atMost Int.compare 1 1)
            , test "less value" (fn _ =>
                expectToFail (Expect.atMost Int.compare 1 2))
            , test "greater value" (fn _ => Expect.atMost Int.compare 2 1)
            , test "fmt equal value" (fn _ =>
                Expect.atMostFmt Int.compare Int.toString 1 1)
            ]
        , describe "atLeast"
            [ test "equal value" (fn _ => Expect.atLeast Int.compare 1 1)
            , test "less value" (fn _ => Expect.atLeast Int.compare 1 2)
            , test "greater value" (fn _ =>
                expectToFail (Expect.atLeast Int.compare 2 1))
            , test "fmt greater value" (fn _ =>
                expectToFail (Expect.atLeastFmt Int.compare Int.toString 2 1))
            ]
        , test "less" (fn _ => Expect.less Int.compare 2 1)
        , test "lessFmt" (fn _ => Expect.lessFmt Int.compare Int.toString 2 1)
        , test "greater" (fn _ => Expect.greater Int.compare 1 2)
        , test "greaterFmt" (fn _ =>
            Expect.greaterFmt Int.compare Int.toString 1 2)
        ]
    end
end

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
        , test "onfail" (fn _ =>
            expectToFail
              (Expect.onfail "This test should fail" (Expect.fail "custom fail")))
        , test "istrue" (fn _ => Expect.istrue true)
        , test "isfalse" (fn _ => Expect.isfalse false)
        , test "equal" (fn _ => Expect.equal Int.compare 1 1)
        , test "equalfmt" (fn _ => Expect.equalfmt Int.compare Int.toString 1 1)
        , test "notequal" (fn _ => Expect.notequal Int.compare 1 2)
        , test "notequalfmt" (fn _ => Expect.notequal Int.compare 1 2)
        , describe "atmost"
            [ test "equal value" (fn _ => Expect.atmost Int.compare 1 1)
            , test "less value" (fn _ =>
                expectToFail (Expect.atmost Int.compare 1 2))
            , test "greater value" (fn _ => Expect.atmost Int.compare 2 1)
            , test "fmt equal value" (fn _ =>
                Expect.atmostfmt Int.compare Int.toString 1 1)
            ]
        , describe "atleast"
            [ test "equal value" (fn _ => Expect.atleast Int.compare 1 1)
            , test "less value" (fn _ => Expect.atleast Int.compare 1 2)
            , test "greater value" (fn _ =>
                expectToFail (Expect.atleast Int.compare 2 1))
            , test "fmt greater value" (fn _ =>
                expectToFail (Expect.atleastfmt Int.compare Int.toString 2 1))
            ]
        , test "less" (fn _ => Expect.less Int.compare 2 1)
        , test "lessfmt" (fn _ => Expect.lessfmt Int.compare Int.toString 2 1)
        , test "greater" (fn _ => Expect.greater Int.compare 1 2)
        , test "greaterfmt" (fn _ =>
            Expect.greaterfmt Int.compare Int.toString 1 2)
        ]
    end
end

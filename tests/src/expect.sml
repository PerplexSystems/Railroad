val expectTests = Test.describe "Expect"
  [ Test.test "istrue" (fn _ => Expect.istrue true)
  , Test.test "isfalse" (fn _ => Expect.isfalse false)
  , Test.test "equal" (fn _ => Expect.equal Int.compare 1 1)
  , Test.test "equalfmt" (fn _ => Expect.equalfmt Int.compare Int.toString 1 1)
  , Test.test "notequal" (fn _ => Expect.notequal Int.compare 1 2)
  , Test.test "notequalfmt" (fn _ => Expect.notequal Int.compare 1 2)
  , Test.describe "atmost"
      [ Test.test "equal value" (fn _ => Expect.atmost Int.compare 1 1)
      , Test.test "less value" (fn _ =>
          expectToFail (Expect.atmost Int.compare 1 2))
      , Test.test "greater value" (fn _ => Expect.atmost Int.compare 2 1)
      , Test.test "fmt equal value" (fn _ =>
          Expect.atmostfmt Int.compare Int.toString 1 1)
      ]
  , Test.describe "atleast"
      [ Test.test "equal value" (fn _ => Expect.atleast Int.compare 1 1)
      , Test.test "less value" (fn _ => Expect.atleast Int.compare 1 2)
      , Test.test "greater value" (fn _ =>
          expectToFail (Expect.atleast Int.compare 2 1))
      , Test.test "fmt greater value" (fn _ =>
          expectToFail (Expect.atleastfmt Int.compare Int.toString 2 1))
      ]
  , Test.test "less" (fn _ => Expect.less Int.compare 2 1)
  , Test.test "lessfmt" (fn _ => Expect.lessfmt Int.compare Int.toString 2 1)
  , Test.test "greater" (fn _ => Expect.greater Int.compare 1 2)
  , Test.test "greaterfmt" (fn _ =>
      Expect.greaterfmt Int.compare Int.toString 1 2)
  ]

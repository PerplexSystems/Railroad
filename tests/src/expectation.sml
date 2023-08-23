structure TestExpectation =
struct

  val tests =
    let
      open Test
      open Expectation
    in
      describe "Expectation"
        [describe "toString"
           [ test "Pass" (fn _ =>
               let
                 val expected = ""
                 val actual = Expectation.toString Expect.pass
               in
                 Expect.equalFmt String.compare String.toString expected actual
               end)

           , describe "Fail"
               [ test "Custom" (fn _ =>
                   let
                     val expected = "Custom description"
                     val expectation =
                       Expectation.fail
                         {description = expected, reason = Expectation.Custom}
                     val actual = Expectation.toString expectation
                   in
                     Expect.equalFmt String.compare String.toString expected
                       actual
                   end)

               , test "Equality" (fn _ =>
                   let
                     val expected = "Expectation.Equality: this is the message."
                     val expectation =
                       Expectation.fail
                         { description = "Expectation.Equality"
                         , reason = Expectation.Equality "this is the message."
                         }
                     val actual = Expectation.toString expectation
                   in
                     Expect.equalFmt String.compare String.toString expected
                       actual
                   end)

               , test "EqualityFormatter" (fn _ =>
                   let
                     val expected =
                       "Expectation.EqualityFormatter\nExpected: foo\nActual: bar"
                     val expectation = Expectation.fail
                       { description = "Expectation.EqualityFormatter"
                       , reason = Expectation.EqualityFormatter ("foo", "bar")
                       }
                     val actual = Expectation.toString expectation
                   in
                     Expect.equalFmt String.compare String.toString expected
                       actual
                   end)

               , describe "Invalid"
                   [ test "EmptyList" (fn _ =>
                       let
                         val expected =
                           "Expectation.EmptyList: list cannot be empty."
                         val expectation =
                           Expectation.fail
                             { description = "Expectation.EmptyList"
                             , reason =
                                 Expectation.Invalid Expectation.EmptyList
                             }
                         val actual = Expectation.toString expectation
                       in
                         Expect.equalFmt String.compare String.toString expected
                           actual
                       end)

                   , test "DuplicatedName" (fn _ =>
                       let
                         val expected = "Expectation.DuplicatedName"
                         val expectation =
                           Expectation.fail
                             { description = expected
                             , reason =
                                 Expectation.Invalid Expectation.DuplicatedName
                             }
                         val actual = Expectation.toString expectation
                       in
                         Expect.equalFmt String.compare String.toString expected
                           actual
                       end)

                   , test "BadDescription" (fn _ =>
                       let
                         val expected =
                           "Expectation.BadDescription: bad description."
                         val expectation =
                           Expectation.fail
                             { description = "Expectation.BadDescription"
                             , reason =
                                 Expectation.Invalid Expectation.BadDescription
                             }
                         val actual = Expectation.toString expectation
                       in
                         Expect.equalFmt String.compare String.toString expected
                           actual
                       end)
                   ]
               ]
           ]]
    end
end

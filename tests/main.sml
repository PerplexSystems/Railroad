fun main _ =
  let
    val tests =
      Test.describe "test list" [
        Test.test "first test" (fn _ => (print ("hello from first test\n"); Expectation.fail { description = "asdas", reason = Expectation.TODO })),
        Test.ftest "first focus test" (fn _ => (print ("hello from foucs test\n"); Expectation.fail { description = "asdas", reason = Expectation.TODO }))
      ]
    val value = PolyML.makestring { a = 1 }
    val a = TyvarExt.makestring { a = 1 }
  in
  
    (print a;
    Runner.run tests)
  end
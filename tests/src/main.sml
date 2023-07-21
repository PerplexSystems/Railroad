structure Main =
struct
  fun main (_: string, _: string list) =
    let open Test
    in
      run (concat [TestExpect.tests, TestRunner.tests, TestExpectation.tests])
    end
end

val _ = Main.main ("", [])

structure INTERNAL_TEST =
struct
  datatype Test =
    UnitTest of (unit -> Expectation.Expectation)
  | Labeled of (string * Test)
  | Skipped of Test
  | Focused of Test
  | Batch of Test list
end

structure INTERNAL_RUNNER = struct

end

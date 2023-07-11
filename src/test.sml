signature TEST =
sig
  structure Expectation : EXPECTATION

  (* I didn't want to expose this, but we need this datatype on the runner *)
  datatype Test =
    UnitTest of (unit -> Expectation.Expectation)
  | Labeled of (string * Test)
  | Skipped of Test
  | Focused of Test
  | Batch of Test list

  val describe: string -> Test list -> Test
  val fdescribe: string -> Test list -> Test
  val sdescribe: string -> Test list -> Test

  val test: string -> (unit -> Expectation.Expectation) -> Test
  val ftest: string -> (unit -> Expectation.Expectation) -> Test
  val stest: string -> (unit -> Expectation.Expectation) -> Test

  val skip: Test -> Test
  val focus: Test -> Test
  val concat: Test list -> Test
end

structure Test: TEST =
struct
  structure Expectation = Expectation
  open Expectation

  datatype Test =
    UnitTest of (unit -> Expectation)
  | Labeled of (string * Test)
  | Skipped of Test
  | Focused of Test
  | Batch of Test list
  (* | FuzzTest (Random.Seed -> Int -> List Expectation) *)

  fun describe description tests = Labeled (description, Batch tests)
  fun fdescribe description tests = Focused (describe description tests)
  fun sdescribe description tests = Skipped (describe description tests)

  fun test description code = Labeled (description, UnitTest code)
  fun ftest description code = Focused (test description code)
  fun stest description code = Skipped (test description code)

  fun skip test = Skipped test
  fun focus test = Focused test

  fun concat tests =
    if List.length tests = 0 then
      UnitTest (fn _ =>
        fail { description = "This `concat` list is empty."
             , reason = Invalid EmptyList })
    else
      (* TODO: validate duplicated names *)
      Batch tests
end

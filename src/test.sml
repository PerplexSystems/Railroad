signature TEST =
sig
  (* I didn't want to expose this, but we need this datatype on the runner *)
  val describe: string -> INTERNAL_TEST.Test list -> INTERNAL_TEST.Test
  val test: string -> (unit -> Expectation.Expectation) -> INTERNAL_TEST.Test
  val skip: INTERNAL_TEST.Test -> INTERNAL_TEST.Test
  val focus: INTERNAL_TEST.Test -> INTERNAL_TEST.Test
  val concat: INTERNAL_TEST.Test list -> INTERNAL_TEST.Test

  val run: INTERNAL_TEST.Test -> Runner.RunResult
  val runwithoptions: Runner.RunnerOption list -> INTERNAL_TEST.Test -> Runner.RunResult
end

structure Test: TEST =
struct
  structure Test = INTERNAL_TEST
  structure Runner = Runner

  structure Expectation = Expectation
  open Expectation

  open Test

  (* | FuzzTest (Random.Seed -> Int -> List Expectation) *)

  fun describe description tests = Labeled (description, Batch tests)
  fun test description code = Labeled (description, UnitTest code)
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

  fun run test = Runner.run test
  fun runwithoptions options test = Runner.runwithoptions options test
end


signature TEST =
sig
  val describe: string -> INTERNAL_TEST.Test list -> INTERNAL_TEST.Test
  val test: string -> (unit -> Expectation.Expectation) -> INTERNAL_TEST.Test
  val skip: INTERNAL_TEST.Test -> INTERNAL_TEST.Test
  val focus: INTERNAL_TEST.Test -> INTERNAL_TEST.Test
  val concat: INTERNAL_TEST.Test list -> INTERNAL_TEST.Test

  val run: INTERNAL_TEST.Test -> unit
end

structure Test: TEST =
struct
  structure Test = INTERNAL_TEST
  structure Expectation = Expectation

  open Expectation
  open Test

  fun describe description tests =
    Labeled (description, Batch tests)

  fun test description code =
    Labeled (description, UnitTest code)

  fun skip test = Skipped test

  fun focus test = Focused test

  fun concat tests =
    if List.length tests = 0 then
      UnitTest (fn _ =>
        fail
          { description = "This `concat` list is empty."
          , reason = Invalid EmptyList
          })
    else
      (* TODO: validate duplicated names *)
      Batch tests

  fun run test = Runner.run test
end

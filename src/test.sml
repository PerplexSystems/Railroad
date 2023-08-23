structure Test:
sig
  type Test = Internal.Test
  structure Configuration: CONFIGURATION

  val describe: string -> Test list -> Test
  val test: string -> (unit -> Expectation.Expectation) -> Test
  val skip: Test -> Test
  val focus: Test -> Test
  val concat: Test list -> Test

  val run: Test -> unit
  val runWithConfig: Configuration.Setting list -> Test -> unit
end =
struct
  structure Configuration = Configuration
  open Expectation
  open Internal

  fun describe description tests =
    let
      val desc = String.trim description
    in
      if desc = "" then
        failnow
          { description = "This `describe` has a blank description."
          , reason = Invalid BadDescription
          }
      else if List.null tests then
        failnow
          { description = "This `describe " ^ desc ^ "` has no tests in it."
          , reason = Invalid EmptyList
          }
      else
        case duplicatedNames tests of
          ERROR dups =>
            let
              fun dupDescription duped =
                "The `describe` '" ^ desc ^ "' Contains multiple tests named '"
                ^ duped ^ "'. Rename them to know which is which."
            in
              Labeled (desc, Internal.failnow
                { description = String.concatWith "\n"
                    (List.map dupDescription dups)
                , reason = Invalid DuplicatedName
                })
            end
        | OK children =>
            if List.exists (fn x => x = desc) children then
              Labeled (desc, Internal.failnow
                { description =
                    "The test '" ^ desc
                    ^ "' contains a child test of the same name '" ^ desc
                    ^ "'. Rename them to know which is which."
                , reason = Invalid DuplicatedName
                })
            else
              Labeled (desc, Batch tests)
    end

  fun test description code =
    let
      val desc = String.trim description
    in
      if desc = "" then blankDescriptionFail
      else Labeled (description, UnitTest code)
    end

  fun skip test = Skipped test
  fun focus test = Focused test

  fun concat tests =
    if List.length tests = 0 then
      UnitTest (fn _ =>
        fail
          { description = "This `concat` has no tests in it."
          , reason = Invalid EmptyList
          })
    else
      case duplicatedNames tests of
        OK _ => Batch tests
      | ERROR duplicates =>
          let
            open Expectation

            fun duplicatedDescription duped =
              "A test group contains multiple tests named '" ^ duped
              ^ "'. Do some renaming so that tests have unique names."

            val description = String.concatWith "\n"
              (List.map duplicatedDescription duplicates)
          in
            failnow {description = description, reason = Invalid DuplicatedName}
          end

  fun run test = Runner.run test
  fun runWithConfig options test = Runner.runWithConfig options test
end

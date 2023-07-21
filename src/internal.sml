structure Internal =
struct
  structure List =
  struct
    open List

    fun concatMap f l =
      List.concat (List.map f l)
  end

  structure String =
  struct
    open String

    val trim = let open Substring
               in string o dropl Char.isSpace o dropr Char.isSpace o full
               end
  end

  datatype Test =
    UnitTest of (unit -> Expectation.Expectation)
  | Labeled of (string * Test)
  | Skipped of Test
  | Focused of Test
  | Batch of Test list

  fun failnow record =
    UnitTest (fn _ => Expectation.fail record)

  val blankDescriptionFail =
    let
      open Expectation
    in
      failnow
        { description =
            "This test has a blank description. Let's give it a useful one!"
        , reason = Invalid BadDescription
        }
    end

  fun duplicatedNames tests =
    let
      fun buildname test =
        case test of
          Labeled (description, _) => [description]
        | Batch subtests => List.concatMap buildname subtests
        | UnitTest _ => []
        | Skipped subTest => buildname subTest
        | Focused subTest => buildname subTest

      fun duplicates [] = []
        | duplicates (x :: xs) =
            if (List.exists (fn y => x = y) xs) then [x] else duplicates xs

      val names = List.concatMap buildname tests
      val duplicatedNames = duplicates names
    in
      if List.null duplicatedNames then NONE else SOME duplicatedNames
    end
end

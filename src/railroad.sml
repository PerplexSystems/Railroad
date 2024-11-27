(*
  Copyright 2023 Perplex Systems

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*)

signature CONFIGURATION =
sig
  datatype Setting = Output of TextIO.outstream | PrintPassed of bool

  type Configuration = {output: TextIO.outstream, printPassed: bool}

  val fromList: Setting list -> Configuration
  val default: Configuration
end

structure Configuration: CONFIGURATION =
struct
  datatype Setting = Output of TextIO.outstream | PrintPassed of bool

  type Configuration = {output: TextIO.outstream, printPassed: bool}

  val default = {output = TextIO.stdOut, printPassed = true}

  fun withOutput newOutput {output = _, printPassed} =
    {output = newOutput, printPassed = printPassed}

  fun withPrintPassed newPrintPassed {output, printPassed = _} =
    {output = output, printPassed = newPrintPassed}

  fun fromList options =
    List.foldl
      (fn (setting, config) =>
        case setting of
          Output newOutput =>
            withOutput newOutput config
        | PrintPassed newPrintPassed =>
            withPrintPassed newPrintPassed config)
    default options
end

signature EXPECTATION =
sig
  datatype InvalidReason = EmptyList | DuplicatedName | BadDescription

  type actual = string
  type expected = string

  datatype Reason =
    Custom
  | Invalid of InvalidReason
  | Equality of string
  | EqualityFormatter of expected * actual

  type fail = {description: string, reason: Reason}
  datatype Expectation = Pass | Fail of fail

  val pass: Expectation
  val fail: fail -> Expectation
  val toString: Expectation -> string
end

structure Expectation: EXPECTATION =
struct
  datatype InvalidReason = EmptyList | DuplicatedName | BadDescription

  type actual = string
  type expected = string

  datatype Reason =
    Custom
  | Invalid of InvalidReason
  | Equality of string
  | EqualityFormatter of expected * actual

  type fail = {description: string, reason: Reason}

  datatype Expectation = Pass | Fail of fail

  val pass = Pass
  fun fail {description: string, reason: Reason} =
    Fail {description = description, reason = reason}

  fun toString expectation =
    case expectation of
      Pass => ""
    | Fail failReason =>
        let
          val {description, reason} = failReason
        in
          case reason of
            Custom => description
          | Equality str => (description ^ ": " ^ str)
          | EqualityFormatter (expected, actual) =>
              (description ^ "\n" ^ "Expected: " ^ expected ^ "\nActual: "
               ^ actual)
          | Invalid invalid =>
              case invalid of
                EmptyList => (description ^ ": " ^ "list cannot be empty.")
              | DuplicatedName => description
              | BadDescription => (description ^ ": " ^ "bad description.")
        end
end

structure Internal =
struct
  datatype ('a, 'e) Result = OK of 'a | ERROR of 'e

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
      fun names test =
        case test of
          Labeled (description, _) => [description]
        | Batch subtests => List.concatMap names subtests
        | UnitTest _ => []
        | Skipped subTest => names subTest
        | Focused subTest => names subTest

      (* we don't have a Set structure for now ;( *)
      fun insertIfNotExists item l =
        if List.exists (fn x => x = item) l then l else item :: l

      fun accumDuplicates (newName, (dups, uniques)) =
        if List.exists (fn unique => unique = newName) uniques then
          (insertIfNotExists newName dups, uniques)
        else
          (dups, insertIfNotExists newName uniques)

      val accumulatedDuplicates = List.concatMap names tests

      val (accDups, accUniques) =
        List.foldl accumDuplicates ([], []) accumulatedDuplicates
    in
      if List.null accDups then OK accUniques else ERROR accDups
    end
end

structure Runner =
struct
  open Expectation
  open Internal

  type Runner = {run: unit -> Expectation, labels: string list}

  datatype Runnable = Thunk of (unit -> Expectation)

  datatype RunnableTree =
    Runnable of Runnable
  | LabeledRunnable of (string * RunnableTree)

  type Distribution =
    { all: RunnableTree list
    , focused: RunnableTree list
    , skipped: RunnableTree list
    }

  type RunReport = {passed: int, failed: int, skipped: int}

  datatype Runners =
    Plain of Runner list
  | Focusing of Runner list
  | Skipping of Runner list
  | Invalid of string

  fun runThunk (Thunk thunk) = thunk ()

  fun fromRunnableTree labels runner =
    case runner of
      Runnable runnable => [{labels = labels, run = fn () => runThunk runnable}]
    | LabeledRunnable (label, subRunner) =>
        fromRunnableTree (labels @ [label]) subRunner

  fun todistribution test =
    case test of
      UnitTest code =>
        {all = [Runnable (Thunk (fn _ => code ()))], focused = [], skipped = []}

    | Labeled (description, ts) =>
        let
          val next = todistribution ts
          val labelTests = (fn tests => LabeledRunnable (description, tests))
        in
          { all = List.map labelTests (#all next)
          , focused = List.map labelTests (#focused next)
          , skipped = List.map labelTests (#skipped next)
          }
        end

    | Batch ts =>
        List.foldl
          (fn (final, prev) =>
             let
               val next = todistribution final
             in
               { all = (#all prev) @ (#all next)
               , focused = (#focused prev) @ (#focused next)
               , skipped = (#skipped prev) @ (#skipped next)
               }
             end) {all = [], focused = [], skipped = []} ts

    | Focused t =>
        let val next = todistribution t
        in {all = (#all next), focused = (#all next), skipped = (#skipped next)}
        end

    | Skipped t =>
        let val next = todistribution t
        in {all = [], focused = [], skipped = (#all next)}
        end

  fun fromTest test =
    let
      val {focused, skipped, all} = todistribution test

      fun countallrunnables trees =
        let
          fun countrunnables runnable =
            case runnable of
              Runnable _ => 1
            | LabeledRunnable (_, runner) => countrunnables runner
        in
          List.foldl (fn (runnable, acc) => (countrunnables runnable) + acc) 0
            trees
        end
    in
      if List.null focused then
        if (countallrunnables skipped) = 0 then
          Plain (Internal.List.concatMap (fromRunnableTree []) all)
        else
          Skipping (Internal.List.concatMap (fromRunnableTree []) all)
      else
        Focusing (Internal.List.concatMap (fromRunnableTree []) focused)
    end

  fun evalrunner (runner: Runner) =
    let
      val {labels, run} = runner
      val label = String.concatWith "." (List.map Internal.String.trim labels)

      val expectation = run ()
      val expectationstr = Expectation.toString expectation
      val str =
        case expectation of
          Pass => "=== PASS: " ^ label
        | Fail _ => "=== FAIL: " ^ label ^ "\n    " ^ expectationstr ^ "\n"
    in
      {result = str ^ "\n", passed = (expectation = Pass)}
    end

  fun runreport runs =
    List.foldl
      (fn ({passed, result}, acc) =>
         if passed then {passed = (#passed acc) + 1, failed = (#failed acc)}
         else {passed = (#passed acc), failed = (#failed acc) + 1})
      {passed = 0, failed = 0} runs

  fun printreport stream {passed, failed} =
    let
      val output =
        ("Passed: " ^ Int.toString passed ^ ", failed: " ^ Int.toString failed
         ^ "\n")
    in
      TextIO.output (stream, output)
    end

  fun runtests stream printPassed runners =
    let
      val runs = (List.map evalrunner runners)
      val report = runreport runs
    in
      ( List.app
        (fn {result, passed} =>
          if not passed orelse printPassed then
            TextIO.output (stream, result)
          else
            ()
        ) runs
      ; report
      )
    end

  fun runWithConfig options test =
    let
      val {output, printPassed} = Configuration.fromList options

      val runners = let open Configuration in fromTest test end
    in
      case runners of
        Plain rs =>
          let
            val report = runtests output printPassed rs
            val _ = printreport output report
          in
            if (#failed report) > 0 then OS.Process.exit OS.Process.failure
            else OS.Process.exit OS.Process.success
          end
      | Skipping rs =>
          let
            val report = runtests output printPassed rs
            val _ = printreport output report
          in
            (* skipping a test should always fail all the tests *)
            OS.Process.exit OS.Process.failure
          end

      | Focusing rs =>
          let
            val report = runtests output printPassed rs
            val _ = printreport output report
          in
            (* focusing a test should always fail all the tests *)
            OS.Process.exit OS.Process.failure
          end
      | Invalid _ => (* TODO *) OS.Process.exit OS.Process.failure
    end

  fun run test = runWithConfig [] test
end

signature TEST =
sig
  type test

  structure Configuration: CONFIGURATION

  val describe: string -> test list -> test
  val test: string -> (unit -> Expectation.Expectation) -> test
  val testTheory: string -> 'a list -> ('a -> Expectation.Expectation) -> test
  val skip: test -> test
  val focus: test -> test
  val concat: test list -> test

  val run: test -> unit
  val runWithConfig: Configuration.Setting list -> test -> unit
end

structure Test: TEST =
struct
  structure Configuration = Configuration
  open Expectation
  open Internal

  type test = Internal.Test

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
          { description = "This `describe` " ^ desc ^ "` has no tests in it."
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

  fun testTheory description theories code =
    let
      val desc = String.trim description

      fun createTest count theory =
        test (Int.toString count) (fn _ => (code theory))

      fun accumulateTests (theory, (count, tests)) =
        let val theoryTest = createTest count theory
        in (count + 1, theoryTest :: tests)
        end

      val (_, tests) = List.foldl accumulateTests (1, []) theories
    in
      if desc = "" then
        failnow
          { description = "This `testTheory` has a blank description."
          , reason = Invalid BadDescription
          }
      else if List.null theories then
        failnow
          { description =
              "This `testTheory` " ^ desc ^ "` has no theories in it."
          , reason = Invalid EmptyList
          }
      else
        describe desc tests
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

  val run = Runner.run
  val runWithConfig = Runner.runWithConfig
end

signature EXPECT =
sig
  type 'a expected = 'a
  type 'a actual = 'a

  type 'a comparer = ('a expected * 'a actual) -> General.order
  type 'a formatter = 'a -> string

  val pass: Expectation.Expectation
  val fail: string -> Expectation.Expectation
  val onFail: string -> Expectation.Expectation -> Expectation.Expectation

  val isTrue: bool actual -> Expectation.Expectation
  val isFalse: bool actual -> Expectation.Expectation

  val some: 'a option actual -> Expectation.Expectation
  val none: 'a option actual -> Expectation.Expectation

  val equal: 'a comparer -> 'a expected -> 'a actual -> Expectation.Expectation
  val equalFmt: 'a comparer
                -> 'a formatter
                -> 'a expected
                -> 'a actual
                -> Expectation.Expectation

  val notEqual: 'a comparer
                -> 'a expected
                -> 'a actual
                -> Expectation.Expectation
  val notEqualFmt: 'a comparer
                   -> 'a formatter
                   -> 'a expected
                   -> 'a actual
                   -> Expectation.Expectation

  val atMost: 'a comparer -> 'a expected -> 'a actual -> Expectation.Expectation
  val atMostFmt: 'a comparer
                 -> 'a formatter
                 -> 'a expected
                 -> 'a actual
                 -> Expectation.Expectation

  val atLeast: 'a comparer
               -> 'a expected
               -> 'a actual
               -> Expectation.Expectation
  val atLeastFmt: 'a comparer
                  -> 'a formatter
                  -> 'a expected
                  -> 'a actual
                  -> Expectation.Expectation

  val less: 'a comparer -> 'a expected -> 'a actual -> Expectation.Expectation
  val lessFmt: 'a comparer
               -> 'a formatter
               -> 'a expected
               -> 'a actual
               -> Expectation.Expectation

  val greater: 'a comparer
               -> 'a expected
               -> 'a actual
               -> Expectation.Expectation
  val greaterFmt: 'a comparer
                  -> 'a formatter
                  -> 'a expected
                  -> 'a actual
                  -> Expectation.Expectation

  datatype FloatingPointTolerance =
    Absolute of real
  | Relative of real
  | AbsoluteOrRelative of (real * real)
end

structure Expect: EXPECT =
struct
  open Expectation

  type 'a expected = 'a
  type 'a actual = 'a

  type 'a comparer = ('a actual * 'a expected) -> General.order
  type 'a formatter = 'a -> string

  val pass = Expectation.Pass
  fun fail str = Expectation.fail {description = str, reason = Custom}
  fun onFail str expectation =
    case expectation of
      Pass => expectation
    | Fail _ => fail str

  fun isTrue actual =
    if actual then
      Pass
    else
      Expectation.fail
        { description = "Expect.isTrue"
        , reason = Equality "The value provided is not true."
        }

  fun isFalse actual =
    if Bool.not actual then
      Pass
    else
      Expectation.fail
        { description = "Expect.isFalse"
        , reason = Equality "The value provided is not false."
        }

  fun some actual =
    case actual of
      SOME _ => Pass
    | _ =>
        Expectation.fail
          { description = "Expect.some"
          , reason = Equality "The value provided is not SOME."
          }

  fun none actual =
    case actual of
      NONE => Pass
    | _ =>
        Expectation.fail
          { description = "Expect.none"
          , reason = Equality "The value provided is not NONE."
          }

  fun equal comparer expected actual =
    case comparer (actual, expected) of
      EQUAL => Pass
    | _ =>
        Expectation.fail
          { description = "Expect.equal"
          , reason = Equality
              "The value provided is not equal to the expected one."
          }

  fun equalFmt comparer formatter expected actual =
    case equal comparer expected actual of
      Pass => Pass
    | _ =>
        Expectation.fail
          { description = "Expect.equalFmt"
          , reason = EqualityFormatter
              ((formatter expected), (formatter actual))
          }

  fun notEqual comparer expected actual =
    case comparer (actual, expected) of
      EQUAL =>
        Expectation.fail
          { description = "Expect.notEqual"
          , reason = Equality "The value provided is equal to the expected one."
          }
    | _ => Pass

  fun notEqualFmt comparer formatter expected actual =
    case notEqual comparer expected actual of
      Pass => Pass
    | _ =>
        Expectation.fail
          { description = "Expect.notEqualFmt"
          , reason = EqualityFormatter
              ((formatter expected), (formatter actual))
          }

  fun atMost comparer expected actual =
    case comparer (actual, expected) of
      GREATER =>
        Expectation.fail
          { description = "Expect.atMost"
          , reason = Equality
              "The value provided is greater than the expected one."
          }
    | _ => Pass

  fun atMostFmt comparer formatter expected actual =
    case atMost comparer expected actual of
      Pass => Pass
    | _ =>
        Expectation.fail
          { description = "Expect.atMostFmt"
          , reason = EqualityFormatter
              ((formatter expected), (formatter actual))
          }

  fun atLeast comparer expected actual =
    case comparer (actual, expected) of
      LESS =>
        Expectation.fail
          { description = "Expect.notEqual"
          , reason = Equality
              "The value provided is less than the expected one."
          }
    | _ => Pass

  fun atLeastFmt comparer formatter expected actual =
    case atLeast comparer expected actual of
      Pass => Pass
    | _ =>
        Expectation.fail
          { description = "Expect.atLeastFmt"
          , reason = EqualityFormatter
              ((formatter expected), (formatter actual))
          }

  fun less comparer expected actual =
    case comparer (actual, expected) of
      LESS => Pass
    | _ =>
        Expectation.fail
          { description = "Expect.less"
          , reason = Equality
              "The value provided is not less than the expected one."
          }

  fun lessFmt comparer formatter expected actual =
    case less comparer expected actual of
      Pass => Pass
    | _ =>
        Expectation.fail
          { description = "Expect.lessFmt"
          , reason = EqualityFormatter
              ((formatter expected), (formatter actual))
          }

  fun greater comparer expected actual =
    case comparer (actual, expected) of
      GREATER => Pass
    | _ =>
        Expectation.fail
          { description = "Expect.greater"
          , reason = Equality
              "The value provided is not greater than the expected one."
          }

  fun greaterFmt comparer formatter expected actual =
    case greater comparer expected actual of
      Pass => Pass
    | _ =>
        Expectation.fail
          { description = "Expect.greaterFmt"
          , reason = EqualityFormatter
              ((formatter expected), (formatter actual))
          }

  datatype FloatingPointTolerance =
    Absolute of real
  | Relative of real
  | AbsoluteOrRelative of (real * real)
end

signature RAILROAD =
sig
  structure Test: TEST
  structure Expect: EXPECT
  structure Configuration: CONFIGURATION
end

structure Railroad =
struct
  structure Test = Test
  structure Expect = Expect
  structure Configuration = Configuration
end

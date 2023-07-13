signature RUNNER = sig
  type Runner = { run: unit -> Expectation.Expectation, labels: string list }

  datatype SeededRunners =
    Plain of Runner list
  | Focused of Runner list
  | Skipping of Runner list
  | Invalid of string

  val fromtest: INTERNAL_TEST.Test -> SeededRunners
  val failurereason: Expectation.Expectation -> Expectation.fail option
end

structure Runner =
struct
  infix  3 |>     fun x |> f = f x

  structure Test = INTERNAL_TEST

  open Expectation

  type RunResult = unit

  type Runner =
    { run: unit -> Expectation
    , labels: string list }

  datatype Runnable = Thunk of (unit -> Expectation)

  datatype RunnableTree =
    Runnable of Runnable
  | Labeled of (string * RunnableTree)

  type Distribution =
    { all: RunnableTree list
    , focused: RunnableTree list
    , skipped: RunnableTree list }

  type RunReport =
    { passed: int
    , failed: int
    , skipped: int }

  datatype Runners
    = Plain of Runner list
    | Focused of Runner list
    | Skipping of Runner list
    | Invalid of string

  fun runThunk (Thunk thunk) = thunk ()

  fun fromRunnableTree labels runner =
    case runner of
      Runnable runnable => [{ labels = labels, run = fn () => runThunk runnable }]
    | Labeled (label, subRunner) => fromRunnableTree (labels @ [ label ]) subRunner

  fun toDistribution test =
    case test of
      Test.UnitTest code =>
        { all = [Runnable (Thunk (fn _ => code ()))]
        , focused = []
        , skipped = [] }

    | Test.Labeled (description, subTest) =>
        let
          val next = toDistribution subTest
          val labelTests = (fn tests => Labeled (description, tests))
        in
          { all = List.map labelTests (#all next)
          , focused = List.map labelTests (#focused next)
          , skipped = List.map labelTests (#skipped next) }
        end

    | Test.Batch subTests =>
        List.foldl
          (fn (test, prev) =>
            let
              val next = toDistribution test
            in
              { all = (#all prev) @ (#all next)
              , focused = (#focused prev) @ (#focused next)
              , skipped = (#skipped prev) @ (#skipped next) }
            end)
          { all = [], focused = [], skipped = [] }
          subTests

    | Test.Focused test =>
        let
          val next = toDistribution test
        in
          { all = (#all next)
          , focused = (#all next)
          , skipped = (#skipped next) }
        end

    | Test.Skipped test =>
        let
          val next = toDistribution test
        in
          { all = []
          , focused = []
          , skipped = (#all next) }
        end

  fun countAllRunnables trees =
    let
      fun countRunnables runnable =
        case runnable of
          Runnable _ => 1
        | Labeled (_, runner) => countRunnables runner
    in
      List.foldl
        (fn (runnable, acc) =>
          (countRunnables runnable) + acc)
        0
        trees
    end

  fun concatMap f m = List.concat (List.map (fn x => f x) m)

  fun fromTest test =
    let
      val distribution = toDistribution test
    in
      if List.null (#focused distribution) then
        if (countAllRunnables (#skipped distribution)) = 0 then
          (#all distribution)
          |> concatMap (fromRunnableTree [])
          |> Plain
        else
          (#all distribution)
          |> concatMap (fromRunnableTree [])
          |> Skipping
      else
          (#focused distribution)
          |> concatMap (fromRunnableTree [])
          |> Focused
    end

  fun runwithoptions (options: unit) test =
    (*
      TODO: where to test for duplicate labels ??????
     *)
    let
      val runners = fromTest test

      fun runRunner (runner: Runner) =
        let
          val label = String.concatWith "." (#labels runner)
          val result = ((#run runner) ())
        in
          (label, result)
        end

    in
      case runners of
        Plain rs =>
          let
            val runs = rs |> List.map runRunner
          in
            runs |> List.app (fn (label, _) => (print (label ^ "\n"); ()))
          end

      | Skipping rs =>

          (OS.Process.exit OS.Process.failure; ())
      | Focused rs =>

          (OS.Process.exit OS.Process.success; ())
      | Invalid str => print "invalid"
    end

  fun run test =
    runwithoptions () test
end

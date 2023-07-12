structure RunnerOption = struct
  type RunnerOption = { sequenced: bool, seed: int option }

  datatype RunnerOption
    = Seed of int option
    | Sequenced

  val empty = { seed = NONE, sequenced = false }

  fun build opts =
    List.foldl (fn (opt, acc) =>
      case opt of
        Seed seed =>
          { seed = seed
          , sequenced = (#sequenced acc) }
      | Sequenced =>
          { seed = (#seed acc)
          , sequenced = true }
    ) empty opts
end

structure Runner  =
struct
  infix  3 |>     fun x |> f = f x

  structure Test = INTERNAL_TEST
  structure RunnerOption = RunnerOption

  open Expectation
  open RunnerOption

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

  datatype SeededRunners
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
          { all = []
          , focused = (#all next)
          , skipped = [] }
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
        else
          (#all distribution)
          |> concatMap (fromRunnableTree [])
      else
          (#focused distribution)
          |> concatMap (fromRunnableTree [])
    end

  (* perharps this should return 0 and 1 so we can fail on CI *)
  fun runwithoptions (options: RunnerOption list) test =
    let
      val runners = fromTest test
      val opts = RunnerOption.build options
    in
      runners
      |> List.app (fn { run, labels } =>
        let
          val label = labels |> String.concatWith "."
          val (result, description) = Expectation.toString (run ())
        in
          (print(result ^ " - " ^ label ^ " " ^ description ^ "\n"))
        end);
        (* TODO: should this exit on test failure? *)
      (OS.Process.exit OS.Process.failure)
    end

  fun run test =
    runwithoptions [ ] test
end

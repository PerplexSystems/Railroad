(* TODO *)
type RunResult = unit

signature RUNNER =
sig
  datatype RunnerOption =
      Seed of int
    | Sequenced

  val runWithOptions: RunnerOption list -> Test.Test -> RunResult
  val run: Test.Test -> RunResult
end

structure Runner: RUNNER =
struct
  open Expectation
  open Test

  datatype RunnerOption =
    Sequenced
  | Seed of int

  type Runner =
    { run: unit -> Expectation
    , labels: string list }

  datatype Runnable = Thunk of (unit -> Expectation)

  datatype RunnableTree =
    Runnable of Runnable
  | Labeled of (string * RunnableTree)

  type Distribution =
    { seed: int
    , all: RunnableTree list
    , focused: RunnableTree list
    , skipped: RunnableTree list }

  fun runThunk (Thunk thunk) = thunk ()

  fun fromRunnableTree labels runner =
    case runner of
      Runnable runnable => [{ labels = labels, run = fn () => runThunk runnable }]
    | Labeled (label, subRunner) => fromRunnableTree (label :: labels) subRunner

  fun distributeSeeds hashed seed test =
    case test of
      Test.UnitTest code =>
        { seed = seed
        , all = [Runnable (Thunk (fn _ => code ()))]
        , focused = []
        , skipped = [] }

    | Test.Labeled (description, subTest) =>
        let
          val next = distributeSeeds hashed seed subTest
          val labelTests = (fn tests => Labeled (description, tests))
        in
          { seed = (#seed next)
          , all = List.map labelTests (#all next)
          , focused = List.map labelTests (#focused next)
          , skipped = List.map labelTests (#skipped next) }
        end

    | Test.Batch subTests =>
        List.foldl
          (fn (test, prev) =>
            let
              val next = distributeSeeds hashed seed test
            in
              { seed = (#seed next)
              , all = (#all prev) @ (#all next)
              , focused = (#focused prev) @ (#focused next)
              , skipped = (#skipped prev) @ (#skipped next) }
            end)
          { seed = 0, all = [], focused = [], skipped = [] }
          subTests

    | Test.Focused test =>
        let
          val next = distributeSeeds hashed seed test
        in
          { seed = (#seed next)
          , all = []
          , focused = (#all next)
          , skipped = [] }
        end

    | Test.Skipped test =>
        let
          val next = distributeSeeds hashed seed test
        in
          { seed = (#seed next)
          , all = []
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

  fun runWithOptions opts test =
    let
      val { all, focused, skipped, ... } = distributeSeeds false 0 test
    in
      (* I do miss the pipe operator *)
      List.app (fn rt =>
        let
          val runners = fromRunnableTree [] rt
        in
          List.app (fn { run, ... } => (run (); ())) runners
        end) all
    end

  fun run test =
    runWithOptions [ Seed 123 ] test

end

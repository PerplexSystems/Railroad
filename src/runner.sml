structure Runner  =
struct
  infix  3 |>     fun x |> f = f x

  open Expectation
  structure Test = INTERNAL_TEST

  type RunResult = unit

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

  fun distributeSeeds seed test =
    case test of
      Test.UnitTest code =>
        { seed = seed
        , all = [Runnable (Thunk (fn _ => code ()))]
        , focused = []
        , skipped = [] }

    | Test.Labeled (description, subTest) =>
        let
          val next = distributeSeeds seed subTest
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
              val next = distributeSeeds seed test
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
          val next = distributeSeeds seed test
        in
          { seed = (#seed next)
          , all = []
          , focused = (#all next)
          , skipped = [] }
        end

    | Test.Skipped test =>
        let
          val next = distributeSeeds seed test
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

  fun concatMap f m = List.concat (List.map (fn x => f x) m)

  fun fromTest seed test =
      let
        val distribution = distributeSeeds seed test
        fun isEmpty l = List.length l = 0
      in
        if isEmpty (#focused distribution) then
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

  fun runwithoptions opts test =
    let
      val seededRunners = fromTest 42 test
    in
      seededRunners
      |> List.app (fn { run, labels } =>
        let
          val label = labels |> String.concatWith "."
          val (result, description) = Expectation.toString (run ())
        in
          (print(result ^ " - " ^ label ^ " " ^ description ^ "\n"))
        end)
    end

  fun run test =
    runwithoptions [ Seed 123 ] test
end

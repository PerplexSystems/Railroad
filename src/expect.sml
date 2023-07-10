signature EXPECT =
sig
  datatype FloatingPointTolerance =
    Absolute of real
  | Relative of real
  | AbsoluteOrRelative of (real * real)

  (* TODO: should this receive a 'comparer' function? *)
  val equal: 'a -> 'a -> ('a -> 'a -> General.order)  -> Expectation.Expectation
  val less: 'a -> 'a -> ('a -> 'a -> General.order)  -> Expectation.Expectation
  val greater: 'a -> 'a -> ('a -> 'a -> General.order)  -> Expectation.Expectation
end

structure Expect: EXPECT =
struct
  open General
  open Expectation

  datatype FloatingPointTolerance =
    Absolute of real
  | Relative of real
  | AbsoluteOrRelative of (real * real)

  fun equal x y comparator =
    case comparator x y of
      EQUAL => Pass
    | _ => Fail

  fun less x y comparator =
    case comparator x y of
      LESS => Pass
    | _ => Fail

  fun greater x y comparator =
    case comparator x y of
      GREATER => Pass
    | _ => Fail
end

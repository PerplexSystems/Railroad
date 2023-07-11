signature EXPECT =
sig
  datatype FloatingPointTolerance =
    Absolute of real
  | Relative of real
  | AbsoluteOrRelative of (real * real)

  val equal: 'a -> 'a -> ('a * 'a -> General.order) -> Expectation.Expectation
  val less: 'a -> 'a -> ('a * 'a -> General.order) -> Expectation.Expectation
  val greater: 'a -> 'a -> ('a * 'a -> General.order) -> Expectation.Expectation
end

structure Expect: EXPECT =
struct
  structure Expectation = Expectation
  open Expectation

  datatype FloatingPointTolerance =
    Absolute of real
  | Relative of real
  | AbsoluteOrRelative of (real * real)

  fun equal x y comparator =
    case comparator(x, y) of
      EQUAL => Pass
    | _ => fail { description = "Expect.equal", reason = Equality "The value provided is not equal to the expected one." }

  fun less x y comparator =
    case comparator(x, y) of
      LESS => Pass
    | _ => fail { description = "Expect.less", reason = Equality "The value provided is not less than the expected one." }

  fun greater x y comparator =
    case comparator(x, y) of
      GREATER => Pass
    | _ => fail { description = "Expect.greater", reason = Equality "The value provided is not greater than the expected one." }
end

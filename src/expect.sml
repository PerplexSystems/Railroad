signature EXPECT =
sig
  type 'a expected = 'a
  type 'a actual = 'a

  type 'a comparer = ('a expected * 'a actual) -> General.order
  type 'a formatter = 'a -> string

  val pass: Expectation.Expectation
  val fail: string -> Expectation.Expectation
  val onfail: string -> Expectation.Expectation -> Expectation.Expectation

  val istrue: bool actual -> Expectation.Expectation
  val isfalse: bool actual -> Expectation.Expectation

  val some: 'a option actual -> Expectation.Expectation
  val none: 'a option actual -> Expectation.Expectation

  val equal: 'a comparer -> 'a expected -> 'a actual -> Expectation.Expectation
  val equalfmt: 'a comparer
                -> 'a formatter
                -> 'a expected
                -> 'a actual
                -> Expectation.Expectation

  val notequal: 'a comparer
                -> 'a expected
                -> 'a actual
                -> Expectation.Expectation
  val notequalfmt: 'a comparer
                   -> 'a formatter
                   -> 'a expected
                   -> 'a actual
                   -> Expectation.Expectation

  val atmost: 'a comparer -> 'a expected -> 'a actual -> Expectation.Expectation
  val atmostfmt: 'a comparer
                 -> 'a formatter
                 -> 'a expected
                 -> 'a actual
                 -> Expectation.Expectation

  val atleast: 'a comparer
               -> 'a expected
               -> 'a actual
               -> Expectation.Expectation
  val atleastfmt: 'a comparer
                  -> 'a formatter
                  -> 'a expected
                  -> 'a actual
                  -> Expectation.Expectation

  val less: 'a comparer -> 'a expected -> 'a actual -> Expectation.Expectation
  val lessfmt: 'a comparer
               -> 'a formatter
               -> 'a expected
               -> 'a actual
               -> Expectation.Expectation

  val greater: 'a comparer
               -> 'a expected
               -> 'a actual
               -> Expectation.Expectation
  val greaterfmt: 'a comparer
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
  structure Expectation = Expectation
  open Expectation

  type 'a expected = 'a
  type 'a actual = 'a

  type 'a comparer = ('a actual * 'a expected) -> General.order
  type 'a formatter = 'a -> string

  val pass = Expectation.Pass
  fun fail str = Expectation.fail {description = str, reason = Custom}
  fun onfail str expectation =
    case expectation of
      Pass => expectation
    | Fail _ => fail str

  fun istrue actual =
    if actual then
      Pass
    else
      Expectation.fail
        { description = "Expect.istrue"
        , reason = Equality "The value provided is not true."
        }

  fun isfalse actual =
    if Bool.not actual then
      Pass
    else
      Expectation.fail
        { description = "Expect.isfalse"
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

  fun equalfmt comparer formatter expected actual =
    case equal comparer expected actual of
      Pass => Pass
    | _ =>
        Expectation.fail
          { description = "Expect.equalfmt"
          , reason = EqualityFormatter
              ((formatter expected), (formatter actual))
          }

  fun notequal comparer expected actual =
    case comparer (actual, expected) of
      EQUAL =>
        Expectation.fail
          { description = "Expect.notequal"
          , reason = Equality "The value provided is equal to the expected one."
          }
    | _ => Pass

  fun notequalfmt comparer formatter expected actual =
    case notequal comparer expected actual of
      Pass => Pass
    | _ =>
        Expectation.fail
          { description = "Expect.notequalfmt"
          , reason = EqualityFormatter
              ((formatter expected), (formatter actual))
          }

  fun atmost comparer expected actual =
    case comparer (actual, expected) of
      GREATER =>
        Expectation.fail
          { description = "Expect.atmost"
          , reason = Equality
              "The value provided is greater than the expected one."
          }
    | _ => Pass

  fun atmostfmt comparer formatter expected actual =
    case atmost comparer expected actual of
      Pass => Pass
    | _ =>
        Expectation.fail
          { description = "Expect.atmostfmt"
          , reason = EqualityFormatter
              ((formatter expected), (formatter actual))
          }

  fun atleast comparer expected actual =
    case comparer (actual, expected) of
      LESS =>
        Expectation.fail
          { description = "Expect.notequal"
          , reason = Equality
              "The value provided is less than the expected one."
          }
    | _ => Pass

  fun atleastfmt comparer formatter expected actual =
    case atleast comparer expected actual of
      Pass => Pass
    | _ =>
        Expectation.fail
          { description = "Expect.atleastfmt"
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

  fun lessfmt comparer formatter expected actual =
    case less comparer expected actual of
      Pass => Pass
    | _ =>
        Expectation.fail
          { description = "Expect.lessfmt"
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

  fun greaterfmt comparer formatter expected actual =
    case greater comparer expected actual of
      Pass => Pass
    | _ =>
        Expectation.fail
          { description = "Expect.greaterfmt"
          , reason = EqualityFormatter
              ((formatter expected), (formatter actual))
          }

  datatype FloatingPointTolerance =
    Absolute of real
  | Relative of real
  | AbsoluteOrRelative of (real * real)
end

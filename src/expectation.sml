signature EXPECTATION = sig
  datatype InvalidReason
    = EmptyList
    | DuplicatedName
    | BadDescription

  datatype Reason
    = Invalid of InvalidReason
    | Equality of string
    | TODO

  type Fail =
    { description: string
    , reason: Reason }

  datatype Expectation
    = Pass
    | Fail of Fail

  val fail: { description: string, reason: Reason } -> Expectation
end

structure Expectation : EXPECTATION = struct
  datatype InvalidReason = EmptyList | DuplicatedName | BadDescription

  datatype Reason
    = Invalid of InvalidReason
    | Equality of string
    | TODO

  type Fail = { description: string, reason: Reason }

  datatype Expectation = Pass | Fail of Fail

  fun fail { description: string, reason: Reason } =
    Fail { description = description, reason = reason }
end

structure Expectation =
struct
  datatype InvalidReason = EmptyList | DuplicatedName | BadDescription

  datatype Reason =
    Custom
  | Invalid of InvalidReason
  | Equality of string
  | TODO

  type fail = { description: string, reason: Reason}

  datatype Expectation = Pass | Fail of fail

  fun fail {description: string, reason: Reason} =
    Fail {description = description, reason = reason}

  val pass = Pass

  fun toString expectation =
    case expectation of
      Pass => ("PASS", "")
    | Fail {description, reason} =>
        case reason of
          Equality str => ("FAIL", String.concatWith " | " [description, str])
        | _ => ("FAIL", "")
end

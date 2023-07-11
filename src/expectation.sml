structure Expectation = struct
  datatype InvalidReason = EmptyList | DuplicatedName | BadDescription

  datatype Reason
    = Invalid of InvalidReason
    | Equality of string
    | TODO

  type Fail = { description: string, reason: Reason }

  datatype Expectation = Pass | Fail of Fail

  fun fail { description: string, reason: Reason } =
    Fail { description = description, reason = reason }

  fun toString expectation =
    case expectation of
      Pass => ("PASS", "")
    | Fail { description, reason } =>
      case reason of
        Equality str => ("FAIL", String.concatWith " | " [ description, str ])
      | _ => ("FAIL", "")
end

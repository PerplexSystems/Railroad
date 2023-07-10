signature EXPECTATION = sig
  datatype Expectation = Pass | Fail
end

structure Expectation : EXPECTATION = struct
  datatype Expectation = Pass | Fail
end

enum EvalResult {
  case integer(Int)
  case string(String)
}

enum VariableTypes {
  case integer(Int)
  case string(String)
  case nilValue
}

func getIntFromEvalResult(_ evalResult: EvalResult) -> Int {
  switch evalResult {
  case .integer(let intValue):
    return intValue
  case .string(let stringValue):
    writeStderrAndExit("Expected integer, got string: \(stringValue)")
  }
  return 0
}

func getStringFromEvalResult(_ evalResult: EvalResult) -> String {
  switch evalResult {
  case .integer(let intValue):
    return String(intValue)
  case .string(let stringValue):
    return stringValue
  }
}

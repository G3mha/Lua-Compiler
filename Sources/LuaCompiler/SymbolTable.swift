class SymbolTable {
  private var variables: [String: VariableTypes] = [:]

  func initVar(_ variable: String, _ value: VariableTypes = .nilValue) {
    if variables.keys.contains(variable) {
      writeStderrAndExit("Variable already initialized: \(variable)")
    } else {
      variables[variable] = value
    }
  }

  func setValue(_ variable: String, _ value: VariableTypes) {
    if let _ = variables[variable] {
      variables[variable] = value
    } else {
      writeStderrAndExit("Attempt to set an uninitialized variable: \(variable)")
    }
  }

  func getValue(_ variable: String) -> VariableTypes? {
    if let value = variables[variable] {
      return value
    } else {
      writeStderrAndExit("Variable not found in SymbolTable: \(variable)")
      return nil
    }
  }
}

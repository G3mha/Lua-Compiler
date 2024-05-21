class SymbolTable {
  private var variables: [String: Any] = [:]

  func initVar(_ variable: String, _ value: Any = .nilValue) {
    if variables.keys.contains(variable) {
      fatalError("Variable already initialized: \(variable)")
    } else {
      variables[variable] = value
    }
  }

  func setValue(_ variable: String, _ value: Any) {
    if let _ = variables[variable] {
      variables[variable] = value
    } else {
      fatalError("Attempt to set an uninitialized variable: \(variable)")
    }
  }

  func getValue(_ variable: String) -> Any? {
    if let value = variables[variable] {
      return value
    } else {
      fatalError("Variable not found in SymbolTable: \(variable)")
      return nil
    }
  }
}

import Foundation

class SymbolTable {
  private var variables: [String: Any?] = [:]

  func initVar(_ variableName: String) {
    if variables.keys.contains(variableName) {
      fatalError("Variable already initialized: \(variableName)")
    } else {
      variables[variableName] = nil
    }
  }

  func setValue(_ variableName: String, _ variableValue: Any) {
    if variables.keys.contains(variableName) {
      variables[variableName] = variableValue
    } else {
      fatalError("Variable not initialized: \(variableName)")
    }
  }

  func getValue(_ variableName: String) -> Any {
    if !variables.keys.contains(variableName) {
      fatalError("Variable not initialized: \(variableName)")
    } else if let variableValue = variables[variableName] {
      return variableValue
    } else {
      fatalError("Value not assigned to variable: \(variableName)")
    }
  }
}

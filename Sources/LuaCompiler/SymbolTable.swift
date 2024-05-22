import Foundation

class SymbolTable {
  private var table: [String: Any?] = [:]

  func initVar(_ variableName: String) {
    if table.keys.contains(variableName) {
      fatalError("Variable already initialized: \(variableName)")
    } else {
      table[variableName] = nil
    }
  }

  func setValue(_ variableName: String, _ variableValue: Any) {
    if table.keys.contains(variableName) {
      table[variableName] = variableValue
    } else {
      fatalError("Variable not initialized: \(variableName)")
    }
  }

  func getValue(_ variableName: String) -> Any {
    if !table.keys.contains(variableName) {
      fatalError("Variable not initialized: \(variableName)")
    } else if let variableValue = table[variableName] {
      return variableValue
    } else {
      fatalError("Value not assigned to variable: \(variableName)")
    }
  }
}

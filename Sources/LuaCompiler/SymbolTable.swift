import Foundation

class SymbolTable {
  private var table: [String: Any?] = [:]

  func initVar(_ variableName: String) {
    table[variableName] = nil
  }

  func setValue(_ variableName: String, _ variableValue: Any) {
    table[variableName] = variableValue
  }

  func getValue(_ variableName: String) -> Any {
    if !table.keys.contains(variableName) {
      fatalError("Variable not initialized: \(variableName)")
    } else if let variableValue = table[variableName] {
      return variableValue
    } else {
      fatalError("Variable \(variableName) is initialized, but has no value assigned")
    }
  }
}

class FuncTable {
  private var table: [String: Any] = [:]

  func setFunction(functionName: String, function: Any) {
    table[functionName] = function
  }

  func getFunction(functionName: String) -> Any? {
    return table[functionName]
  }
}

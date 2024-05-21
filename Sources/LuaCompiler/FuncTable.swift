class FuncTable {
  private var table: [String: Any] = [:]

  func setFunction(functionName: String, functionArgs: Any, functionBody: Any) {
    table[functionName] = (functionArgs, functionBody)
  }

  func getFunction(functionName: String) -> Any? {
    return table[functionName]
  }
}

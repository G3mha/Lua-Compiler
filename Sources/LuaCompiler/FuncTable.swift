class FuncTable {
  private var table: [String: ([String], [Node])] = [:]

  func setFunction(_ functionName: String, _ functionArgs: [String], _ functionBody: [Node]) {
    table[functionName] = (functionArgs, functionBody)
  }

  func getFunction(_ functionName: String) -> (functionArgs: [String], functionBody: [Node]) {
    return table[functionName]
  }
}

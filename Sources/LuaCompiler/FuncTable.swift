class FuncTable {
  private var table: [String: ([String], [Node])] = [:]

  func 

  func setFunction(_ functionName: String, _ functionArgs: [String], _ functionBody: [Node]) {
    table[functionName] = (functionArgs, functionBody)
  }

  func getFunction(_ functionName: String) -> (functionArgs: [String], functionBody: [Node]) {
    if table.keys.contains(functionName) {
      return table[functionName]
    } else {
      fatalError("Function not defined: \(functionName)")
    }
  }
}

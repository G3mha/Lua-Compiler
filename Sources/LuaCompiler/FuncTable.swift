class FuncTable {
  private var table: [String: ([String], Block)] = [:]

  func 

  func setFunction(_ functionName: String, _ functionArgs: [String], _ functionBody: Block) {
    table[functionName] = (functionArgs, functionBody)
  }

  func getFunction(_ functionName: String) -> (functionArgs: [String], functionBody: Block) {
    if table.keys.contains(functionName) {
      return table[functionName]
    } else {
      fatalError("Function not defined: \(functionName)")
    }
  }
}

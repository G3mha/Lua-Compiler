class FuncTable {
  private var table: [String: ([String], Block)] = [:]

  func setFunction(_ functionName: String, _ functionArgs: [VarDec], _ functionBody: Block) {
    table[functionName] = (functionArgs, functionBody)
  }

  func getFunction(_ functionName: String) -> (functionArgs: [VarDec], functionBody: Block) {
    if table.keys.contains(functionName) {
      return table[functionName]
    } else {
      fatalError("Function not defined: \(functionName)")
    }
  }
}

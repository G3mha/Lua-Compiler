class FuncTable {
  private var table: [String: ([VarDec], Block)] = [:]

  func setFunction(_ functionName: String, _ functionArgs: [VarDec], _ functionBody: Block) {
    table[functionName] = (functionArgs, functionBody)
  }

  func getFunction(_ functionName: String) -> (functionArgs: [VarDec], functionBody: Block) {
    if table.keys.contains(functionName) {
      if let functionData = table[functionName] {
        return functionData
      } else {
        fatalError("Function \(functionName) is initialized, but has no value assigned")
      }
    } else {
      fatalError("Function not defined: \(functionName)")
    }
  }
}

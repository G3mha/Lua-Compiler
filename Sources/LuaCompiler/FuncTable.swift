class FuncTable {
  private var table: [String: Any] = [:]

  func setFunction(function: String, value: Any) {
    table[function] = value
  }

  func getFunction(function: String) -> Any? {
    return table[function]
  }
}

protocol Node {
  var value: String { get set }
  var children: [Node] { get set }
  func evaluate(symbolTable: SymbolTable, funcTable: FuncTable) -> Any
}

class BinOp: Node {
  var value: String
  var children: [Node]

  init(value: String, children: [Node]) {
    self.value = value
    self.children = children
  }

  func evaluate(symbolTable: SymbolTable, funcTable: FuncTable) -> Any {
    let firstValue = self.children[0].evaluate(symbolTable: symbolTable, funcTable: funcTable)
    let secondValue = self.children[1].evaluate(symbolTable: symbolTable, funcTable: funcTable)

    if firstValue is Integer && secondValue is Integer {
      switch self.value {
        case "PLUS":
          return firstValue + secondValue
        case "MINUS":
          return firstValue - secondValue
        case "MUL":
          return firstValue * secondValue
        case "DIV":
          return firstValue / secondValue
        case "GT":
          return (firstValue > secondValue) ? 1 : 0
        case "LT":
          return (firstValue < secondValue) ? 1 : 0
        case "EQ":
          return (firstValue == secondValue) ? 1 : 0
        case "AND":
          return (firstValue == 1 && secondValue == 1) ? 1 : 0
        case "OR":
          return (firstValue == 1 || secondValue == 1) ? 1 : 0
        case "CONCAT":
          return firstValue + secondValue
        default:
          fatalError("Unsupported binary operation on integers")
      }
    } else if firstValue is String && secondValue is String {
      switch self.value {
        case "CONCAT":
          return firstValue + secondValue
        case "EQ":
          return (firstValue == secondValue) ? 1 : 0
        case "GT":
          return (firstValue > secondValue) ? 1 : 0
        case "LT":
          return (firstValue < secondValue) ? 1 : 0
        default:
          fatalError("Unsupported binary operation on strings")
      }
    } else {
      switch self.value {
        case "CONCAT":
          return String(firstValue) + String(secondValue)
        default:
          fatalError("Unsupported binary operation on strings")
      }
    }
    return 0
  }
}

class UnOp: Node {
  var value: String
  var children: [Node]

  init(value: String, children: [Node]) {
    self.value = value
    self.children = children
  }

  func evaluate(symbolTable: SymbolTable, funcTable: FuncTable) -> Any {
    let result = self.children[0].evaluate(symbolTable: symbolTable, funcTable: funcTable)

    if result is String {
      fatalError("Cannot perform unary arithmetic operations on Strings")
    }

    if result == "NOT" {
      return (result == 0) ? 1 : 0
    } else if result == "MINUS" {
      return -result
    } else if result == "PLUS" {
      return result
    } else {
      fatalError("Unsupported unary operation on integers")
    }
    return 0
  }
}

class IntVal: Node {
  var value: String
  var children: [Node]

  init(value: String, children: [Node]) {
    self.value = value
    self.children = children
  }

  func evaluate(symbolTable: SymbolTable, funcTable: FuncTable) -> Any {
    return Int(self.value)
  }
}

class StringVal: Node {
  var value: String
  var children: [Node]

  init(value: String, children: [Node]) {
    self.value = value
    self.children = children
  }

  func evaluate(symbolTable: SymbolTable, funcTable: FuncTable) -> Any {
    return String(self.value)
  }
}

class NoOp: Node {
  var value: String
  var children: [Node]

  init(value: String, children: [Node]) {
    self.value = value
    self.children = children
  }

  func evaluate(symbolTable: SymbolTable, funcTable: FuncTable) -> Any {
    return 0
  }
}

class VarDec: Node {
  var value: String
  var children: [Node]

  init(value: String, children: [Node]) {
    self.value = value
    self.children = children
  }

  func evaluate(symbolTable: SymbolTable, funcTable: FuncTable) -> Any {
    let variableValue = self.children[0].evaluate(symbolTable: symbolTable, funcTable: funcTable)

    guard case let variableName = self.children[1].evaluate(symbolTable: symbolTable, funcTable: funcTable) else {
      fatalError("Invalid variable name in declaration")
      return 0
    }

    symbolTable.setValue(variableName, variableValue)

    return 0
  }
}

class FuncDec: Node {
  var value: String
  var children: [Node]

  init(value: String, children: [Node]) {
    self.value = value
    self.children = children
  }

  func evaluate(symbolTable: SymbolTable, funcTable: FuncTable) -> Any {
    guard case let funcName = self.children[0].evaluate(symbolTable: symbolTable, funcTable: funcTable) else {
      fatalError("Invalid function name in function declaration")
      return 0
    }
    
    guard case let funcArgs = self.children[1].evaluate(symbolTable: symbolTable, funcTable: funcTable) else {
      fatalError("Invalid function arguments in function declaration")
      return 0
    }

    let funcBody = self.children[2]
    funcTable.setFunction(funcName, funcArgs, funcBody)

    return 0
  }
}

class FuncCall: Node {
  var value: String
  var children: [Node]

  init(value: String, children: [Node]) {
    self.value = value
    self.children = children
  }

  func evaluate(symbolTable: SymbolTable, funcTable: FuncTable) -> Any {
    guard case let funcName = self.children[0].evaluate(symbolTable: symbolTable, funcTable: funcTable) else { 
      fatalError("Invalid function name in function call")
      return 0
    }
    
    guard case let funcArgs = self.children[1].evaluate(symbolTable: symbolTable, funcTable: funcTable) else {
      fatalError("Invalid function arguments in function call")
      return 0
    }

    let (funcArgsFromTable, funcBodyFromTable) = FuncTable.getFunction(funcName)!

    if funcArgs.count != funcArgsFromTable.count {
      fatalError("Invalid number of arguments in function call")
    }


    guard let function = FuncTable.getFunction(funcName) else {
      fatalError("Function \(funcName) not found")
      return 0
    }

    return function.evaluate(symbolTable: symbolTable, funcTable: funcTable)
  }
}

class Return: Node {
  var value: String
  var children: [Node]

  init(value: String, children: [Node]) {
    self.value = value
    self.children = children
  }

  func evaluate(symbolTable: SymbolTable, funcTable: FuncTable) -> Any {
    return self.children[0].evaluate(symbolTable: symbolTable, funcTable: funcTable)
  }
}

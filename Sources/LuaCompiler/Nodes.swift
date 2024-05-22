protocol Node {
  var value: String { get set }
  var children: [Node] { get set }
  func evaluate(symbolTable: SymbolTable, funcTable: FuncTable) -> Any
}

class Block: Node {
  var value: String
  var children: [Node]

  init(value: String, children: [Node]) {
    self.value = value
    self.children = children
  }

  func evaluate(symbolTable: SymbolTable, funcTable: FuncTable) -> Any {
    for node in self.children {
      let _ = node.evaluate(symbolTable: symbolTable, funcTable: funcTable)
    }
    return 0
  }
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
    let variableName = self.children[0].evaluate(symbolTable: symbolTable, funcTable: funcTable) as! String
    symbolTable.initVar(variableName)
    return 0
  }
}

class VarAssign: Node {
  var value: String
  var children: [Node]

  init(value: String, children: [Node]) {
    self.value = value
    self.children = children
  }

  func evaluate(symbolTable: SymbolTable, funcTable: FuncTable) -> Any {
    let variableValue = self.children[0].evaluate(symbolTable: symbolTable, funcTable: funcTable)
    let variableName = self.children[1].evaluate(symbolTable: symbolTable, funcTable: funcTable) as! String
    guard case let variableName = self.children[1].evaluate(symbolTable: symbolTable, funcTable: funcTable) else {
      fatalError("Invalid variable name in assignment")
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

  func evaluate(symbolTable: SymbolTable, funcTable: FuncTable) -> Int {
    let funcName = self.children[0].evaluate(symbolTable: symbolTable, funcTable: funcTable) as! String
    let funcArgs = self.children[1].evaluate(symbolTable: symbolTable, funcTable: funcTable) as! [String]
    let funcBody = self.children[2].evaluate(symbolTable: symbolTable, funcTable: funcTable) as! [Node]
    
    guard case let funcArgs = self.children[1].evaluate(symbolTable: symbolTable, funcTable: funcTable) as? [String] else {
      fatalError("Invalid function arguments in function declaration")
    }

    guard case let funcBody = self.children[2].evaluate(symbolTable: symbolTable, funcTable: funcTable) as? [Node] else {
      fatalError("Invalid function body in function declaration")
    }

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
    let funcName = self.children[0].evaluate(symbolTable: symbolTable, funcTable: funcTable) as! String
    let funcArgs = self.children[1].evaluate(symbolTable: symbolTable, funcTable: funcTable)

    if let funcData = funcTable.getFunction(funcName) {
      let funcArgsFromTable = funcData.0
      let funcBodyFromTable = funcData.1

      if (funcArgs as? [Node])?.count != (funcArgsFromTable as? [Node])?.count {
        fatalError("Invalid number of arguments in function call")
      }

      let localSymbolTable = SymbolTable()
      if let funcArgs = funcArgs as? [Node] {
        for i in 0..<funcArgs.count {
          let evaluatedValue = funcArgs[i].evaluate(symbolTable: symbolTable, funcTable: funcTable)
          let unwrappedFuncArgsFromTable = funcArgsFromTable.compactMap { $0 }
          localSymbolTable.initVar(unwrappedFuncArgsFromTable[i], evaluatedValue)
        }
      } else {
        fatalError("funcArgs is not of type [Node]")
      }
      var result: Any = 0
      for node in funcBodyFromTable {
        if let unwrappedNode = node {
          result = unwrappedNode.evaluate(symbolTable: localSymbolTable, funcTable: funcTable)
        } else {
          fatalError("Invalid function body")
        }
      }
      return result
    } else {
      fatalError("Invalid function name")
    }
  }
}

class WhileOp: Node {
  var value: String
  var children: [Node]

  init(value: String, children: [Node]) {
    self.value = value
    self.children = children
  }

  func evaluate(symbolTable: SymbolTable, funcTable: FuncTable) -> Any {
    let condition = self.children[0].evaluate(symbolTable: symbolTable, funcTable: funcTable)
    let body = self.children[1].evaluate(symbolTable: symbolTable, funcTable: funcTable)

    if condition is Int {
      while condition as! Int == 1 {
        for node in body as! [Node] {
          let _ = node.evaluate(symbolTable: symbolTable, funcTable: funcTable)
        }
      }
    } else {
      fatalError("Invalid condition in while loop")
    }

    return 0
  }
}
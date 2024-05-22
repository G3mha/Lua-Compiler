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
      let nodeValue = node.evaluate(symbolTable: symbolTable, funcTable: funcTable)
      if node is ReturnOp {
        return nodeValue
      }
    }
    return 0
  }
}

class ReturnOp: Node {
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
    if let intValue = Int(self.value) {
      return intValue
    } else {
      fatalError("Invalid integer value")
    }
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
    symbolTable.initVar(self.value)
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
    symbolTable.setValue(self.value, variableValue)
    return 0
  }
}

class VarAccess: Node {
  var value: String
  var children: [Node]

  init(value: String, children: [Node]) {
    self.value = value
    self.children = children
  }

  func evaluate(symbolTable: SymbolTable, funcTable: FuncTable) -> Any {
    return symbolTable.getValue(self.value)
  }
}

class FuncArgs: Node {
  var value: String
  var children: [Node]

  init(value: String, children: [Node]) {
    self.value = value
    self.children = children
  }

  func evaluate(symbolTable: SymbolTable, funcTable: FuncTable) -> Any {
    self.children[0]
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
    let funcBody = self.children[0] as! Block
    let funcArgs: [VarDec] = []
    for i in 1..<self.children.count {
      funcArgs.append(self.children[i] as! VarDec)
    }
    funcTable.setFunction(self.value, funcArgs, funcBody)
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
    let funcData = funcTable.getFunction(self.value)
    let funcArgsFromTable = funcData.0 as! [VarDec]
    let funcBodyFromTable = funcData.1 as! Block

    if self.children.count != funcArgsFromTable.count {
      fatalError("Invalid number of arguments for function \(funcName)")
    }

    let localSymbolTable = SymbolTable()

    for i in 0..<funcArgsFromTable.count {
      localSymbolTable.initVar(funcArgsFromTable[i].value)
    }

    for i in 0..<self.children.count {
      let evaluatedValue = self.children[i].evaluate(symbolTable: symbolTable, funcTable: funcTable)
      localSymbolTable.setValue(funcArgsFromTable[i].value, evaluatedValue)
    }
    
    return funcBodyFromTable.evaluate(symbolTable: localSymbolTable, funcTable: funcTable)
  }
}

class Statements: Node {
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

class WhileOp: Node {
  var value: String
  var children: [Node]

  init(value: String, children: [Node]) {
    self.value = value
    self.children = children
  }

  func evaluate(symbolTable: SymbolTable, funcTable: FuncTable) -> Any {
    let condition = self.children[0]
    let statements = self.children[1]
    while condition.evaluate(symbolTable: symbolTable, funcTable: funcTable) as! Int == 1 {
      let _ = statements.evaluate(symbolTable: symbolTable, funcTable: funcTable)
    }
    return 0
  }
}

class IfOp: Node {
  var value: String
  var children: [Node]

  init(value: String, children: [Node]) {
    self.value = value
    self.children = children
  }

  func evaluate(symbolTable: SymbolTable, funcTable: FuncTable) -> Any {
    let condition = self.children[0]
    let ifStatements = self.children[1]
    let elseStatements = self.children[2]

    if condition.evaluate(symbolTable: symbolTable, funcTable: funcTable) as! Int == 1 {
      let _ = ifStatements.evaluate(symbolTable: symbolTable, funcTable: funcTable)
    } else {
      let _ = elseStatements.evaluate(symbolTable: symbolTable, funcTable: funcTable)
    }
    return 0
  }
}

class ReadOp: Node {
  var value: String
  var children: [Node]

  init(value: String, children: [Node]) {
    self.value = value
    self.children = children
  }

  func evaluate(symbolTable: SymbolTable, funcTable: FuncTable) -> Any {
    let readValue = readLine()
    if readValue == "true" {
      return 1
    } else if readValue == "false" {
      return 0
    } else if let intValue = Int(readValue!) {
      return intValue
    } else {
      return readValue
    }
  }
}

class PrintOp: Node {
  var value: String
  var children: [Node]

  init(value: String, children: [Node]) {
    self.value = value
    self.children = children
  }

  func evaluate(symbolTable: SymbolTable, funcTable: FuncTable) -> Any {
    let printValue = self.children[0].evaluate(symbolTable: symbolTable, funcTable: funcTable)
    print(printValue)
    return 0
  }
}
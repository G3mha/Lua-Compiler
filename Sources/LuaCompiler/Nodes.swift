protocol Node {
  var value: String { get set }
  var children: [Node] { get set }
  func evaluate(symbolTable: SymbolTable) -> EvalResult
}

class BinOp: Node {
  var value: String
  var children: [Node]

  init(value: String, children: [Node]) {
    self.value = value
    self.children = children
  }

  func evaluate(symbolTable: SymbolTable) -> EvalResult {
    let firstValue = self.children[0].evaluate(symbolTable: symbolTable)
    let secondValue = self.children[1].evaluate(symbolTable: symbolTable)

    switch (firstValue, secondValue) {
      case let (.integer(firstVal), .integer(secondVal)):
        switch self.value {
          case "PLUS":
            return .integer(Int(firstVal) + Int(secondVal))
          case "MINUS":
            return .integer(Int(firstVal) - Int(secondVal))
          case "MUL":
            return .integer(Int(firstVal) * Int(secondVal))
          case "DIV":
            return .integer(Int(firstVal) / Int(secondVal))
          case "GT":
            return .integer((Int(firstVal) > Int(secondVal)) ? 1 : 0)
          case "LT":
            return .integer((Int(firstVal) < Int(secondVal)) ? 1 : 0)
          case "EQ":
            return .integer((Int(firstVal) == Int(secondVal)) ? 1 : 0)
          case "AND":
            return .integer((Int(firstVal) == 1 && Int(secondVal) == 1) ? 1 : 0)
          case "OR":
            return .integer((Int(firstVal) == 1 || Int(secondVal) == 1) ? 1 : 0)
          case "CONCAT":
            return .string(String(firstVal) + String(secondVal))
          default:
            return .integer(0)
        }
      case let (.string(firstVal), .string(secondVal)):
        switch self.value {
          case "CONCAT":
            return .string(firstVal + secondVal)
          case "EQ":
            return .integer((firstVal == secondVal) ? 1 : 0)
          case "GT":
            return .integer((firstVal > secondVal) ? 1 : 0)
          case "LT":
            return .integer((firstVal < secondVal) ? 1 : 0)
          default:
            writeStderrAndExit("Unsupported binary operation on strings")
        }
      default:
        switch self.value {
          case "CONCAT":
            return .string(getStringFromEvalResult(firstValue) + getStringFromEvalResult(secondValue))
          default:
            writeStderrAndExit("Unsupported binary operation on strings")
        }
    }
    return .integer(0) // Default return in case of an error, consider a better error handling strategy
  }
}

class UnOp: Node {
  var value: String
  var children: [Node]

  init(value: String, children: [Node]) {
    self.value = value
    self.children = children
  }

  func evaluate(symbolTable: SymbolTable) -> EvalResult {
    let result = self.children[0].evaluate(symbolTable: symbolTable)

    switch result {
    case .integer(let intValue):
      switch self.value {
      case "NOT":
        return .integer((Int(intValue) == 0) ? 1 : 0)
      case "PLUS":
        return .integer(Int(intValue))
      case "MINUS":
        return .integer(-Int(intValue))
      default:
        writeStderrAndExit("Unsupported unary operation on integers")
      }
    case .string(_):
      writeStderrAndExit("Cannot perform unary arithmetic operations on Strings")
    }

    // Default return in case of an error or unsupported type
    return .integer(0)
  }
}

class IntVal: Node {
  var value: String
  var children: [Node]

  init(value: String, children: [Node]) {
    self.value = value
    self.children = children
  }

  func evaluate(symbolTable: SymbolTable) -> EvalResult {
    if let intValue = Int(self.value) {
      return .integer(intValue)
    } else {
      writeStderrAndExit("IntVal value could not cast String to Int")
    }
    return .integer(0)
  }
}

class StringVal: Node {
  var value: String
  var children: [Node]

  init(value: String, children: [Node]) {
    self.value = value
    self.children = children
  }

  func evaluate(symbolTable: SymbolTable) -> EvalResult {
    return .string(self.value)
  }
}

class NoOp: Node {
  var value: String
  var children: [Node]

  init(value: String, children: [Node]) {
    self.value = value
    self.children = children
  }

  func evaluate(symbolTable: SymbolTable) -> EvalResult {
    return .integer(0)
  }
}

class Declaration: Node {
  var value: String
  var children: [Node]

  init(value: String, children: [Node]) {
    self.value = value
    self.children = children
  }

  func evaluate(symbolTable: SymbolTable) -> EvalResult {
    // Evaluate the right-hand side of the declaration
    let variableValue = self.children[0].evaluate(symbolTable: symbolTable)
    
    // Get the variable name
    guard case let .string(variableName) = self.children[1].evaluate(symbolTable: symbolTable) else {
      writeStderrAndExit("Invalid variable name in declaration")
      return .integer(0) // Return default value
    }
    
    // Set the variable value in the symbol table
    if case let .integer(intValue) = variableValue {
      symbolTable.setValue(variableName, .integer(intValue))
    } else if case let .string(strValue) = variableValue {
      symbolTable.setValue(variableName, .string(strValue))
    }
    
    // Return the evaluated value
    return variableValue
  }
}

class FuncDec: Node {
  var value: String
  var children: [Node]

  init(value: String, children: [Node]) {
    self.value = value
    self.children = children
  }

  func evaluate(symbolTable: SymbolTable) -> EvalResult {
    // Get the function name
    guard case let .string(funcName) = self.children[0].evaluate(symbolTable: symbolTable) else {
      writeStderrAndExit("Invalid function name in function declaration")
      return .integer(0) // Return default value
    }
    
    // Get the function arguments
    guard case let .string(args) = self.children[1].evaluate(symbolTable: symbolTable) else {
      writeStderrAndExit("Invalid function arguments in function declaration")
      return .integer(0) // Return default value
    }
    
    // Get the function body
    let funcBody = self.children[2]
    
    // Set the function in the symbol table
    symbolTable.setFunction(funcName, args, funcBody)
    
    // Return the function name
    return .string(funcName)
  }
}

class FuncCall: Node {
  var value: String
  var children: [Node]

  init(value: String, children: [Node]) {
    self.value = value
    self.children = children
  }

  func evaluate(symbolTable: SymbolTable) -> EvalResult {
    // Get the function name
    guard case let .string(funcName) = self.children[0].evaluate(symbolTable: symbolTable) else {
      writeStderrAndExit("Invalid function name in function call")
      return .integer(0) // Return default value
    }
    
    // Get the function arguments
    guard case let .string(args) = self.children[1].evaluate(symbolTable: symbolTable) else {
      writeStderrAndExit("Invalid function arguments in function call")
      return .integer(0) // Return default value
    }
    
    // Get the function from the symbol table
    guard let func = symbolTable.getFunction(funcName) else {
      writeStderrAndExit("Function \(funcName) not found")
      return .integer(0) // Return default value
    }
    
    // Evaluate the function body
    return func.evaluate(symbolTable: symbolTable)
  }
}

class Return: Node {
  var value: String
  var children: [Node]

  init(value: String, children: [Node]) {
    self.value = value
    self.children = children
  }

  func evaluate(symbolTable: SymbolTable) -> EvalResult {
    return self.children[0].evaluate(symbolTable: symbolTable)
  }
}

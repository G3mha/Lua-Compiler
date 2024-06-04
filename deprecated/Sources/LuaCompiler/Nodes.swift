import Foundation

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

    if let firstInt = firstValue as? Int, let secondInt = secondValue as? Int {
      if self.value == "PLUS" { return firstInt + secondInt }
      if self.value == "MINUS" { return firstInt - secondInt }
      if self.value == "MUL" { return firstInt * secondInt }
      if self.value == "DIV" { return firstInt / secondInt }
      if self.value == "GT" { return firstInt > secondInt ? 1 : 0 }
      if self.value == "LT" { return firstInt < secondInt ? 1 : 0 }
      if self.value == "EQ" { return firstInt == secondInt ? 1 : 0 }
      if self.value == "AND" { return firstInt == 1 && secondInt == 1 ? 1 : 0 }
      if self.value == "OR" { return firstInt == 1 || secondInt == 1 ? 1 : 0 }
      if self.value == "CONCAT" { return String(firstInt) + String(secondInt) }
    } else if let firstString = firstValue as? String, let secondString = secondValue as? String {
      if self.value == "GT" { return firstString > secondString ? 1 : 0 }
      if self.value == "LT" { return firstString < secondString ? 1 : 0 }
      if self.value == "EQ" { return firstString == secondString ? 1 : 0 }
      if self.value == "CONCAT" { return firstString + secondString }
    } else if let firstInt = firstValue as? Int, let secondString = secondValue as? String {
      if self.value == "CONCAT" { return String(firstInt) + secondString }
    } else if let firstString = firstValue as? String, let secondInt = secondValue as? Int {
      if self.value == "CONCAT" { return firstString + String(secondInt) }
    }
    fatalError("Unsupported types for comparison: \(type(of: firstValue)) and \(type(of: secondValue))")
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
    let result = self.children[0].evaluate(symbolTable: symbolTable, funcTable: funcTable) as! Int
    if self.value == "NOT" {
      return (result == 0) ? 1 : 0
    } else if self.value == "MINUS" {
      return -result
    } else if self.value == "PLUS" {
      return result
    } else {
      fatalError("Unsupported unary operation on integers")
    }
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

class FuncDec: Node {
  var value: String
  var children: [Node]

  init(value: String, children: [Node]) {
    self.value = value
    self.children = children
  }

  func evaluate(symbolTable: SymbolTable, funcTable: FuncTable) -> Any {
    let funcBody = self.children.last as! Block
    var funcArgs: [VarDec] = []
    for i in 0..<self.children.count-1 {
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
    let funcArgsFromTable = funcData.0
    let funcBodyFromTable = funcData.1

    if self.children.count != funcArgsFromTable.count {
      fatalError("Invalid number of arguments for function \(self.value)")
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
    if let intValue = Int(readValue!) {
      return intValue as Any
    } else {
      fatalError("Invalid integer value read from input")
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
    if let printInt = printValue as? Int {
      print(printInt)
    } else if let printString = printValue as? String {
      print(printString)
    } else {
      fatalError("Unsupported type for print operation")
    }
    return 0
  }
}
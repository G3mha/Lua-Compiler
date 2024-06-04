import Foundation


class PrePro {
  static public func filter(code: String) -> String {
    let splittedCode = code.replacingOccurrences(of: "\t", with: "").split(separator: "\n")
    var processedCode = ""
    for i in 0..<splittedCode.count {
      let line = splittedCode[i]
      if line.contains("--") {
        if line.prefix(2) != "--" {
          processedCode += String(line.split(separator: "--")[0]) + "\n"
        }
      } else {
        processedCode += String(line) + "\n"
      }
    }
    return processedCode
  }
}

class SymbolTable {
  private var table: [String: Any?] = [:]

  func initVar(_ variableName: String) {
    if table.keys.contains(variableName) {
      writeStderrAndExit("Variable already initialized: \(variableName)")
    }
    table[variableName] = nil as Any?
  }

  func setValue(_ variableName: String, _ variableValue: Any) {
    if !table.keys.contains(variableName) {
      writeStderrAndExit("Variable not initialized: \(variableName)")
    }
    table[variableName] = variableValue
  }

  func getValue(_ variableName: String) -> Any {
    if !table.keys.contains(variableName) {
      writeStderrAndExit("Variable not initialized: \(variableName)")
      return 0
    } else if let variableValue = table[variableName] {
      return variableValue as Any
    }
    writeStderrAndExit("Variable \(variableName) is initialized, but has no value assigned")
    return 0
  }
}

protocol Node {
  var value: String { get set }
  var children: [Node] { get set }
  func evaluate(symbolTable: SymbolTable) -> Any
}

class Block: Node {
  var value: String
  var children: [Node]

  init(value: String, children: [Node]) {
    self.value = value
    self.children = children
  }

  func evaluate(symbolTable: SymbolTable) -> Any {
    for node in self.children {
      let _ = node.evaluate(symbolTable: symbolTable)
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

  func evaluate(symbolTable: SymbolTable) -> Any {
    let firstValue = self.children[0].evaluate(symbolTable: symbolTable)
    let secondValue = self.children[1].evaluate(symbolTable: symbolTable)

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
    writeStderrAndExit("Unsupported types for comparison: \(type(of: firstValue)) and \(type(of: secondValue))")
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

  func evaluate(symbolTable: SymbolTable) -> Any {
    let result = self.children[0].evaluate(symbolTable: symbolTable) as! Int
    if self.value == "NOT" {
      return (result == 0) ? 1 : 0
    } else if self.value == "MINUS" {
      return -result
    } else if self.value == "PLUS" {
      return result
    }
    writeStderrAndExit("Unsupported unary operation on integers")
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

  func evaluate(symbolTable: SymbolTable) -> Any {
    if let intValue = Int(self.value) {
      return intValue
    }
    writeStderrAndExit("Invalid integer value")
    return 0
  }
}

class StringVal: Node {
  var value: String
  var children: [Node]

  init(value: String, children: [Node]) {
    self.value = value
    self.children = children
  }

  func evaluate(symbolTable: SymbolTable) -> Any {
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

  func evaluate(symbolTable: SymbolTable) -> Any {
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

  func evaluate(symbolTable: SymbolTable) -> Any {
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

  func evaluate(symbolTable: SymbolTable) -> Any {
    let variableValue = self.children[0].evaluate(symbolTable: symbolTable)
    symbolTable.setValue(self.value, variableValue)
    return 0
  }
}

class VarDecAndAssign: Node {
  var value: String
  var children: [Node]

  init(value: String, children: [Node]) {
    self.value = value
    self.children = children
  }

  func evaluate(symbolTable: SymbolTable) -> Any {
    let variableValue = self.children[0].evaluate(symbolTable: symbolTable)
    symbolTable.initVar(self.value)
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

  func evaluate(symbolTable: SymbolTable) -> Any {
    return symbolTable.getValue(self.value)
  }
}

class Statements: Node {
  var value: String
  var children: [Node]

  init(value: String, children: [Node]) {
    self.value = value
    self.children = children
  }

  func evaluate(symbolTable: SymbolTable) -> Any {
    for node in self.children {
      let _ = node.evaluate(symbolTable: symbolTable)
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

  func evaluate(symbolTable: SymbolTable) -> Any {
    let condition = self.children[0]
    let statements = self.children[1]
    while condition.evaluate(symbolTable: symbolTable) as! Int == 1 {
      let _ = statements.evaluate(symbolTable: symbolTable)
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

  func evaluate(symbolTable: SymbolTable) -> Any {
    let condition = self.children[0]
    let ifStatements = self.children[1]
    let elseStatements = self.children[2]

    if condition.evaluate(symbolTable: symbolTable) as! Int == 1 {
      let _ = ifStatements.evaluate(symbolTable: symbolTable)
    } else {
      let _ = elseStatements.evaluate(symbolTable: symbolTable)
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

  func evaluate(symbolTable: SymbolTable) -> Any {
    let readValue = readLine()
    if let intValue = Int(readValue!) {
      return intValue as Any
    }
    writeStderrAndExit("Invalid integer value read from input")
    return 0
  }
}

class PrintOp: Node {
  var value: String
  var children: [Node]

  init(value: String, children: [Node]) {
    self.value = value
    self.children = children
  }

  func evaluate(symbolTable: SymbolTable) -> Any {
    let printValue = self.children[0].evaluate(symbolTable: symbolTable)
    if let printInt = printValue as? Int {
      print(printInt)
    } else if let printString = printValue as? String {
      print(printString)
    } else {
      writeStderrAndExit("Unsupported type for print operation")
    }
    return 0
  }
}

class Token {
  var type: String
  var value: String

  init(type: String, value: String) {
    self.type = type
    self.value = value
  }
}

class Tokenizer {
  var source: String
  var position: Int
  var next: Token

  init(source: String) {
    self.source = source
    self.position = 0
    self.next = Token(type: "", value: "0")
  }

  func selectNext() -> Void {
    if position < source.count {
      var char = source[source.index(source.startIndex, offsetBy: position)]
      var tokenWord = ""
      while char == " " && position < source.count {
        position += 1
        char = source[source.index(source.startIndex, offsetBy: position)]
      }
      if char == "+" {
        self.next = Token(type: "PLUS", value: "0")
      } else if char == "-" {
        self.next = Token(type: "MINUS", value: "0")
      } else if char == "*" {
        self.next = Token(type: "MUL", value: "0")
      } else if char == "/" {
        self.next = Token(type: "DIV", value: "0")
      } else if char == "(" {
        self.next = Token(type: "LPAREN", value: "0")
      } else if char == ")" {
        self.next = Token(type: "RPAREN", value: "0")
      } else if char == ">" {
        self.next = Token(type: "GT", value: "0")
      } else if char == "<" {
        self.next = Token(type: "LT", value: "0")
      } else if char == "=" {
        if source[source.index(source.startIndex, offsetBy: position+1)] == "=" {
          self.next = Token(type: "EQ", value: "0")
          position += 1
        } else {
          self.next = Token(type: "ASSIGN", value: "0")
        }
      } else if char == "." {
        if source[source.index(source.startIndex, offsetBy: position+1)] == "." {
          self.next = Token(type: "CONCAT", value: "0")
          position += 1
        } else {
          writeStderrAndExit("Invalid character \(tokenWord)")
        }
      } else if char == "\n" {
        self.next = Token(type: "EOL", value: "0")
      } else if char == "\"" {
        position += 1
        while position < source.count {
          let nextChar = source[source.index(source.startIndex, offsetBy: position)]
          if nextChar == "\"" {
            break
          } else if nextChar == "\n"{
            writeStderrAndExit("Forgot to close string with \"")
          } else {
            tokenWord += String(nextChar)
          }
          position += 1
        }
        if source[source.index(source.startIndex, offsetBy: position)] != "\"" {
          writeStderrAndExit("Forgot to close string with \"")
        }
        self.next = Token(type: "STRING", value: tokenWord)
      } else if char.isNumber {
        while position < source.count {
          let nextChar = source[source.index(source.startIndex, offsetBy: position)]
          if nextChar.isNumber {
            tokenWord += String(nextChar)
          } else {
            break
          }
          position += 1
        }
        position -= 1
        self.next = Token(type: "NUMBER", value: tokenWord)
      } else if char.isLetter {
        while position < source.count {
          let nextChar = source[source.index(source.startIndex, offsetBy: position)]
          if nextChar.isLetter || nextChar.isNumber || nextChar == "_" {
            tokenWord += String(nextChar)
          } else {
            break
          }
          position += 1
        }
        position -= 1
        if ["print", "if", "else", "while", "do", "then", "end", "and", "or", "not", "read", "local"].contains(tokenWord) {
          self.next = Token(type: tokenWord.uppercased(), value: "0")
        } else {
          self.next = Token(type: "IDENTIFIER", value: tokenWord)
        }
      } else {
        writeStderrAndExit("Invalid character \(tokenWord)")
      }
      position += 1
    } else {
      self.next = Token(type: "EOF", value: "0")
    }
  }
}

class Parser {
  var tokenizer: Tokenizer

  init() {
    self.tokenizer = Tokenizer(source: "")
  }

  private func parseFactor(symbolTable: SymbolTable) -> Node {
    if tokenizer.next.type == "NUMBER" {
      let factorValue = tokenizer.next.value
      tokenizer.selectNext()
      return IntVal(value: factorValue, children: [])
    } else if tokenizer.next.type == "STRING" {
      let factorValue = tokenizer.next.value
      tokenizer.selectNext()
      return StringVal(value: factorValue, children: [])
    } else if tokenizer.next.type == "IDENTIFIER" {
      let name = tokenizer.next.value
      tokenizer.selectNext()
      return VarAccess(value: name, children: [])
    } else if tokenizer.next.type == "PLUS" || tokenizer.next.type == "MINUS" || tokenizer.next.type == "NOT" {
      let operatorType = tokenizer.next.type
      tokenizer.selectNext()
      return UnOp(value: operatorType, children: [parseFactor(symbolTable: symbolTable)])
    } else if tokenizer.next.type == "LPAREN" {
      tokenizer.selectNext()
      let result = parseBoolExpression(symbolTable: symbolTable)
      if tokenizer.next.type != "RPAREN" {
        writeStderrAndExit("Missing closing parenthesis")
      }
      tokenizer.selectNext()
      return result
    } else if tokenizer.next.type == "READ" {
      tokenizer.selectNext()
      if tokenizer.next.type != "LPAREN" {
        writeStderrAndExit("Missing opening parenthesis for read statement")
      }
      tokenizer.selectNext()
      if tokenizer.next.type != "RPAREN" {
        writeStderrAndExit("Missing closing parenthesis for read statement")
      }
      tokenizer.selectNext()
      return ReadOp(value: "READ", children: [])
    } else {
      writeStderrAndExit("Invalid factor: (\(tokenizer.next.type), \(tokenizer.next.value))")
    }
    return NoOp(value: "", children: [])
  }

  private func parseTerm(symbolTable: SymbolTable) -> Node {
    var result = parseFactor(symbolTable: symbolTable)
    while tokenizer.next.type == "MUL" || tokenizer.next.type == "DIV" {
      let operatorType = tokenizer.next.type
      tokenizer.selectNext()
      result = BinOp(value: operatorType, children: [result, parseFactor(symbolTable: symbolTable)])
    }
    return result
  }

  private func parseExpression(symbolTable: SymbolTable) -> Node {
    var result = parseTerm(symbolTable: symbolTable)
    while tokenizer.next.type == "PLUS" || tokenizer.next.type == "MINUS" || tokenizer.next.type == "CONCAT" {
      let operatorType = tokenizer.next.type
      tokenizer.selectNext()
      result = BinOp(value: operatorType, children: [result, parseTerm(symbolTable: symbolTable)])
    }
    return result
  }

  private func parseRelationalExpression(symbolTable: SymbolTable) -> Node {
    var result = parseExpression(symbolTable: symbolTable)
    while tokenizer.next.type == "GT" || tokenizer.next.type == "LT" || tokenizer.next.type == "EQ" {
      let operatorType = tokenizer.next.type
      tokenizer.selectNext()
      result = BinOp(value: operatorType, children: [result, parseExpression(symbolTable: symbolTable)])
    }
    return result
  }

  private func parseBooleanTerm(symbolTable: SymbolTable) -> Node {
    var result = parseRelationalExpression(symbolTable: symbolTable)
    while tokenizer.next.type == "AND" {
      let operatorType = tokenizer.next.type
      tokenizer.selectNext()
      result = BinOp(value: operatorType, children: [result, parseRelationalExpression(symbolTable: symbolTable)])
    }
    return result
  }

  private func parseBoolExpression(symbolTable: SymbolTable) -> Node {
    var result = parseBooleanTerm(symbolTable: symbolTable)
    while tokenizer.next.type == "OR" {
      let operatorType = tokenizer.next.type
      tokenizer.selectNext()
      result = BinOp(value: operatorType, children: [result, parseBooleanTerm(symbolTable: symbolTable)])
    }
    return result
  }

  private func parseStatement(symbolTable: SymbolTable) -> Node {
    if tokenizer.next.type == "EOL" {
      tokenizer.selectNext()
      return NoOp(value: "", children: [])
    } else if tokenizer.next.type == "IDENTIFIER" {
      let name = tokenizer.next.value
      tokenizer.selectNext()
      if tokenizer.next.type == "ASSIGN" {
        tokenizer.selectNext()
        let expression = parseBoolExpression(symbolTable: symbolTable)
        return VarAssign(value: name, children: [expression])
      } else {
        writeStderrAndExit("Invalid statement")
      }
    } else if tokenizer.next.type == "PRINT" {
      tokenizer.selectNext()
      if tokenizer.next.type != "LPAREN" {
        writeStderrAndExit("Missing opening parenthesis for print statement")
      }
      tokenizer.selectNext()
      let expression = parseBoolExpression(symbolTable: symbolTable)
      if tokenizer.next.type != "RPAREN" {
        writeStderrAndExit("Missing closing parenthesis for print statement")
      }
      tokenizer.selectNext()
      return PrintOp(value: "PRINT", children: [expression])
    } else if tokenizer.next.type == "WHILE" {
      tokenizer.selectNext()
      let condition = parseBoolExpression(symbolTable: symbolTable)
      if tokenizer.next.type != "DO" {
        writeStderrAndExit("Missing DO after WHILE condition")
      }
      tokenizer.selectNext()
      if tokenizer.next.type != "EOL" {
        writeStderrAndExit("Missing EOL after DO")
      }
      tokenizer.selectNext()
      var statements: [Node] = []
      while tokenizer.next.type != "END" {
        let statement = parseStatement(symbolTable: symbolTable)
        statements.append(statement)
      }
      tokenizer.selectNext()
      if tokenizer.next.type != "EOL" {
        writeStderrAndExit("Missing EOL after END")
      }
      return WhileOp(value: "WHILE", children: [condition, Statements(value: "", children: statements)])
    } else if tokenizer.next.type == "IF" {
      tokenizer.selectNext()
      let condition = parseBoolExpression(symbolTable: symbolTable)
      if tokenizer.next.type != "THEN" {
        writeStderrAndExit("Missing THEN after IF condition")
      }
      tokenizer.selectNext()
      if tokenizer.next.type != "EOL" {
        writeStderrAndExit("Missing EOL after THEN")
      }
      tokenizer.selectNext()
      var ifStatements: [Node] = []
      while tokenizer.next.type != "END" && tokenizer.next.type != "ELSE" {
        let statement = parseStatement(symbolTable: symbolTable)
        ifStatements.append(statement)
      }
      var elseStatements: [Node] = []
      if tokenizer.next.type == "ELSE" {
        tokenizer.selectNext()
        while tokenizer.next.type != "END" {
          let statement = parseStatement(symbolTable: symbolTable)
          elseStatements.append(statement)
        }
      }
      tokenizer.selectNext()
      if tokenizer.next.type != "EOL" {
        writeStderrAndExit("Missing EOL after END")
      }
      return IfOp(value: "IF", children: [condition, Statements(value: "", children: ifStatements), Statements(value: "", children: elseStatements)])
    } else if tokenizer.next.type == "LOCAL" {
      tokenizer.selectNext()
      if tokenizer.next.type != "IDENTIFIER" {
        writeStderrAndExit("Invalid variable name in declaration")
      }
      let variableName = tokenizer.next.value
      tokenizer.selectNext()
      if tokenizer.next.type == "ASSIGN" {
        tokenizer.selectNext()
        let expression = parseBoolExpression(symbolTable: symbolTable)
        return VarDecAndAssign(value: variableName, children: [expression])
      } else {
        return VarDec(value: variableName, children: [])
      }
    }
    writeStderrAndExit("Invalid statement")
    return NoOp(value: "", children: [])
  }

  private func parseBlock(symbolTable: SymbolTable) -> Node {
    var statements: [Node] = []
    while tokenizer.next.type != "EOF" {
      let statement = parseStatement(symbolTable: symbolTable)
      statements.append(statement)
    }
    return Block(value: "", children: statements)
  }

  public func run(code: String, symbolTable: SymbolTable) -> Node {
    let filteredCode = PrePro.filter(code: code)
    self.tokenizer = Tokenizer(source: filteredCode)
    tokenizer.selectNext() // Position the tokenizer to the first token
    return parseBlock(symbolTable: symbolTable)
  }
}


func writeStderrAndExit(_ message: String) {
  // function that writes to stderr a received string and exits with error
  fputs("ERROR: \(message)\n", stderr) // write to stderr
  exit(1) // exit with error
}

func readFile(_ path: String) -> String {
  do {
    let contents = try String(contentsOfFile: path, encoding: .utf8)
    return contents
  } catch {
    writeStderrAndExit("Failed to read file")
    return ""
  }
}

func main() {
  // Ensure there is at least one command line argument for the file path.
  guard CommandLine.arguments.count > 1 else {
    writeStderrAndExit("Please provide a .lua file path.")
    return
  }

  let fileContent = readFile(CommandLine.arguments[1])
  let symbolTable = SymbolTable()
  let myParser = Parser()
  let ast = myParser.run(code: fileContent, symbolTable: symbolTable)
  let _ = ast.evaluate(symbolTable: symbolTable)
}

main()
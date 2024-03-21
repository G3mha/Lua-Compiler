import Foundation

// function that writes to stderr a received string and exits with error
func writeStderrAndExit(_ message: String) {
  fputs("ERROR: \(message)\n", stderr) // write to stderr
  exit(1) // exit with error
}

class PrePro {
  static public func filter(code: String) -> String {
    let splittedCode = code.split(separator: "\n")
    var processedCode = ""
    for i in 0..<splittedCode.count {
      let line = splittedCode[i]
      if line.contains("--") {
        processedCode += String(line.split(separator: "--")[0])
      } else {
        processedCode += String(line)
      }
    }
    processedCode = processedCode.replacingOccurrences(of: " ", with: "")
    return processedCode
  }
}

protocol Node {
  var value: String { get set }
  var children: [Node] { get set }
  func evaluate(symbolTable: SymbolTable) -> Int
}

class BinOp: Node {
  var value: String
  var children: [Node]

  init(value: String, children: [Node]) {
    self.value = value
    self.children = children
  }

  func evaluate(symbolTable: SymbolTable) -> Int {
    if self.value == "+" {
      return self.children[0].evaluate(symbolTable: symbolTable) + self.children[1].evaluate(symbolTable: symbolTable)
    } else if self.value == "-" {
      return self.children[0].evaluate(symbolTable: symbolTable) - self.children[1].evaluate(symbolTable: symbolTable)
    } else if self.value == "*" {
      return self.children[0].evaluate(symbolTable: symbolTable) * self.children[1].evaluate(symbolTable: symbolTable)
    } else if self.value == "/" {
      return self.children[0].evaluate(symbolTable: symbolTable) / self.children[1].evaluate(symbolTable: symbolTable)
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

  func evaluate(symbolTable: SymbolTable) -> Int {
    if self.value == "+" {
      return self.children[0].evaluate(symbolTable: symbolTable)
    } else if self.value == "-" {
      return -self.children[0].evaluate(symbolTable: symbolTable)
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

  func evaluate(symbolTable: SymbolTable) -> Int {
    let intValue = Int(self.value) ?? -1
    if intValue == -1 {
      writeStderrAndExit("IntVal could not cast String to Int")
    }
    return intValue
  }
}

class NoOp: Node {
  var value: String
  var children: [Node]

  init(value: String, children: [Node]) {
    self.value = value
    self.children = children
  }

  func evaluate(symbolTable: SymbolTable) -> Int {
    return 0
  }
}

class SymbolTable {
  private var variables: [String: Int] = [:]

  func setValue(_ variable: String, _ value: Int) {
    variables[variable] = value
  }

  func getValue(_ variable: String) -> Int {
    // if variable is not in the dictionary, return 0
    if variables[variable] == nil {
      writeStderrAndExit("Variable not found in SymbolTable: \(variable)")
      return 0
    }
    return variables[variable]!
  }
}

class Token {
  var type: String
  var value: Int

  init(type: String, value: Int) {
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
    self.next = Token(type: "", value: 0)
  }

  func selectNext() -> Void {
    if position < source.count {
      let char = source[source.index(source.startIndex, offsetBy: position)]
      if char == "*" || char == "/" {
        if self.next.type == "PLUS" || self.next.type == "MINUS" || self.next.type == "MUL" || self.next.type == "DIV" {
          writeStderrAndExit("Double operators")
        }
      }
      if char == "+" || char == "-" {
        if self.next.type == "MUL" || self.next.type == "DIV" {
          writeStderrAndExit("Double operators")
        }
      }
      if char == "+" {
        self.next = Token(type: "PLUS", value: 0)
      } else if char == "-" {
        self.next = Token(type: "MINUS", value: 0)
      } else if char == "*" {
        self.next = Token(type: "MUL", value: 0)
      } else if char == "/" {
        self.next = Token(type: "DIV", value: 0)
      } else if char == "(" {
        self.next = Token(type: "LPAREN", value: 0)
      } else if char == ")" {
        self.next = Token(type: "RPAREN", value: 0)
      } else if char == "=" {
        self.next = Token(type: "ASSIGN", value: 0)
      } else if char.isNumber {
        var numberString = String(char)
        var nextPosition = position + 1
        while nextPosition < source.count {
          let nextChar = source[source.index(source.startIndex, offsetBy: nextPosition)]
          if nextChar.isNumber {
            numberString += String(nextChar)
            nextPosition += 1
          } else {
            break
          }
        }
        self.next = Token(type: "NUMBER", value: Int(numberString) ?? 0)
        position = nextPosition - 1
      } else if char.isLetter {
        var variableString = String(char)
        var nextPosition = position + 1
        while nextPosition < source.count {
          let nextChar = source[source.index(source.startIndex, offsetBy: nextPosition)]
          if nextChar.isLetter || nextChar.isNumber || nextChar == "_" {
            variableString += String(nextChar)
            nextPosition += 1
          } else {
            break
          }
        }
        if variableString == "print" {
          self.next = Token(type: "PRINT", value: 0)
        } else {
          self.next = Token(type: "VARIABLE", value: 0)
        }
        position = nextPosition - 1
      } else {
        writeStderrAndExit("Invalid character")
      }
      position += 1
    } else {
      self.next = Token(type: "EOF", value: 0)
    }
  }
}

class Parser {
  var tokenizer: Tokenizer

  init() {
    self.tokenizer = Tokenizer(source: "")
  }

  public func run(code: String) -> Node {
    let filteredCode = PrePro.filter(code: code)
    self.tokenizer = Tokenizer(source: filteredCode)
    tokenizer.selectNext() // Position the tokenizer to the first token
    return parseBlock()
  }

  private func parseFactor() -> Node {
    var result: Node = NoOp(value: "", children: [])
    if tokenizer.next.type == "NUMBER" {
      result = IntVal(value: String(tokenizer.next.value), children: [])
      tokenizer.selectNext()
    } else if tokenizer.next.type == "PLUS" {
      tokenizer.selectNext()
      result = UnOp(value: "+", children: [parseFactor()])
    } else if tokenizer.next.type == "MINUS" {
      tokenizer.selectNext()
      result = UnOp(value: "-", children: [parseFactor()])
    } else if tokenizer.next.type == "LPAREN" {
      tokenizer.selectNext()
      result = parseExpression()
      if tokenizer.next.type != "RPAREN" {
        writeStderrAndExit("Missing closing parenthesis")
      }
      tokenizer.selectNext()
    } else if tokenizer.next.type == "VARIABLE" {
      let variableName = String(tokenizer.next.value)
      tokenizer.selectNext()
      if tokenizer.next.type == "=" {
        tokenizer.selectNext()
        let variableValue = parseExpression().evaluate(symbolTable: SymbolTable())
        symbolTable.setValue(variableName, variableValue)
        result = NoOp(value: "", children: [])
      } else {
        let variableValue = symbolTable.getValue(variableName)
        result = IntVal(value: String(variableValue), children: [])
      }
    } else if tokenizer.next.type == "PRINT" {
      tokenizer.selectNext()
      if tokenizer.next.type != "LPAREN" {
        writeStderrAndExit("Missing opening parenthesis for print statement")
      }
      tokenizer.selectNext()
      let printValue = parseExpression().evaluate(symbolTable: SymbolTable())
      print(printValue)
      if tokenizer.next.type != "RPAREN" {
        writeStderrAndExit("Missing closing parenthesis for print statement")
      }
      tokenizer.selectNext()
      result = NoOp(value: "", children: [])
    } else if tokenizer.next.type == "EOF" {
      writeStderrAndExit("Last value missing")
    } else {
      writeStderrAndExit("Invalid input")
    }
    return result
  }

  private func parseTerm() -> Node {
    var result = parseFactor()
    while tokenizer.next.type == "MUL" || tokenizer.next.type == "DIV" {
      if tokenizer.next.type == "MUL" {
        tokenizer.selectNext()
        result = BinOp(value: "*", children: [result, parseFactor()])
      } else if tokenizer.next.type == "DIV" {
        tokenizer.selectNext()
        result = BinOp(value: "/", children: [result, parseFactor()])
      }
    }
    return result
  }

  private func parseExpression() -> Node {
    var result = parseTerm()
    while tokenizer.next.type == "PLUS" || tokenizer.next.type == "MINUS" {
      if tokenizer.next.type == "PLUS" {
        tokenizer.selectNext()
        result = BinOp(value: "+", children: [result, parseTerm()])
      } else if tokenizer.next.type == "MINUS" {
        tokenizer.selectNext()
        result = BinOp(value: "-", children: [result, parseTerm()])
      }
    }
    return result
  }

  private func parsePrint() -> Node {
    tokenizer.selectNext()
    if tokenizer.next.type != "LPAREN" {
      writeStderrAndExit("Missing opening parenthesis for print statement")
    }
    tokenizer.selectNext()
    let printValue = parseExpression().evaluate(symbolTable: SymbolTable())
    if tokenizer.next.type != "RPAREN" {
      writeStderrAndExit("Missing closing parenthesis for print statement")
    }
    tokenizer.selectNext()
    print(printValue)
    return NoOp(value: "", children: [])
  }

  private func parseAssignment() -> Node {
    let variableName = String(tokenizer.next.value)
    tokenizer.selectNext()
    if tokenizer.next.type != "ASSIGN" {
      writeStderrAndExit("Missing assignment operator")
    }
    tokenizer.selectNext()
    let variableValue = parseExpression().evaluate(symbolTable: SymbolTable())
    symbolTable.setValue(variableName, variableValue)
    return NoOp(value: "", children: [])
  }

  private func parseStatement() -> Node {
    if tokenizer.next.type == "VARIABLE" {
      return parseAssignment()
    } else if tokenizer.next.type == "PRINT" {
      return parsePrint()
    } else if tokenizer.next.type == "EOF" {
      return NoOp(value: "", children: [])
    } else {
      writeStderrAndExit("Invalid statement")
      return NoOp(value: "", children: [])
    }
  }

  private func parseBlock() -> Node {
    var statements: [Node] = []
    while tokenizer.next.type != "EOF" {
      let statement = parseStatement()
      statements.append(statement)
    }
    return NoOp(value: "", children: statements)
  }
}

func readFile(_ path: String) -> String {
  do {
    let contents = try String(contentsOfFile: path, encoding: .utf8)
    return contents
  } catch {
    writeStderrAndExit("Failed to read file")
    return "Error"
  }
}

let fileContent = readFile(CommandLine.arguments[1])
let myParser = Parser()
let symbolTable = SymbolTable()
let ast = myParser.run(code: fileContent)
let result = ast.evaluate(symbolTable: symbolTable)

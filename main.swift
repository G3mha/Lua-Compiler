import Foundation

// function that writes to stderr a received string and exits with error
func writeStderrAndExit(_ message: String) {
  fputs("ERROR: \(message)\n", stderr) // write to stderr
  exit(1) // exit with error
}

class PrePro {
  static public func filter(code: String) -> String {
    let splittedCode = code.replacingOccurrences(of: " ", with: "").split(separator: "\n")
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

protocol Node {
  var value: String { get set }
  var children: [Node] { get set }
  func evaluate() -> Int
}

class BinOp: Node {
  var value: String
  var children: [Node]

  init(value: String, children: [Node]) {
    self.value = value
    self.children = children
  }

  func evaluate() -> Int {
    if self.value == "+" {
      return self.children[0].evaluate() + self.children[1].evaluate()
    } else if self.value == "-" {
      return self.children[0].evaluate() - self.children[1].evaluate()
    } else if self.value == "*" {
      return self.children[0].evaluate() * self.children[1].evaluate()
    } else if self.value == "/" {
      return self.children[0].evaluate() / self.children[1].evaluate()
    } else if self.value == "or" {
      return self.children[0].evaluate() || self.children[1].evaluate()
    } else if self.value == "and" {
      return self.children[0].evaluate() && self.children[1].evaluate()
    } else if self.value == "==" {
      return self.children[0].evaluate() == self.children[1].evaluate()
    } else if self.value == ">" {
      return self.children[0].evaluate() > self.children[1].evaluate()
    } else if self.value == "<" {
      return self.children[0].evaluate() < self.children[1].evaluate()
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

  func evaluate() -> Int {
    if self.value == "+" {
      return self.children[0].evaluate()
    } else if self.value == "-" {
      return -self.children[0].evaluate()
    } else if self.value == "not" {
      return !self.children[0].evaluate()
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

  func evaluate() -> Int {
    guard let intValue = Int(self.value) else {
      writeStderrAndExit("IntVal could not cast String to Int")
      return 0
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

  func evaluate() -> Int {
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
  var keyword: String

  init(type: String, value: Int) {
    self.type = type
    self.value = value
    self.keyword = ""
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
      } else if char == "\n" {
        self.next = Token(type: "EOL", value: 0)
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
          self.next = Token(type: "IDENTIFIER", value: 0)
          self.next.keyword = variableString
        }
        position = nextPosition - 1
      } else {
        writeStderrAndExit("Invalid character \(char)")
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

  private func parseFactor(symbolTable: SymbolTable) -> Node {
    var result: Node = NoOp(value: "", children: [])
    if tokenizer.next.type == "NUMBER" {
      result = IntVal(value: String(tokenizer.next.value), children: [])
      tokenizer.selectNext()
    } else if tokenizer.next.type == "PLUS" {
      tokenizer.selectNext()
      result = UnOp(value: "+", children: [parseFactor(symbolTable: symbolTable)])
    } else if tokenizer.next.type == "MINUS" {
      tokenizer.selectNext()
      result = UnOp(value: "-", children: [parseFactor(symbolTable: symbolTable)])
    } else if tokenizer.next.type == "LPAREN" {
      tokenizer.selectNext()
      result = parseExpression(symbolTable: symbolTable)
      if tokenizer.next.type != "RPAREN" {
        writeStderrAndExit("Missing closing parenthesis")
      }
      tokenizer.selectNext()
    } else if tokenizer.next.type == "IDENTIFIER" {
      let variableName = String(tokenizer.next.keyword)
      tokenizer.selectNext()
      let variableValue = symbolTable.getValue(variableName)
      result = IntVal(value: String(variableValue), children: [])
    } else if tokenizer.next.type == "EOF" {
      writeStderrAndExit("Last value missing")
    } else {
      writeStderrAndExit("Invalid input")
    }
    return result
  }

  private func parseTerm(symbolTable: SymbolTable) -> Node {
    var result = parseFactor(symbolTable: symbolTable)
    while tokenizer.next.type == "MUL" || tokenizer.next.type == "DIV" {
      if tokenizer.next.type == "MUL" {
        tokenizer.selectNext()
        result = BinOp(value: "*", children: [result, parseFactor(symbolTable: symbolTable)])
      } else if tokenizer.next.type == "DIV" {
        tokenizer.selectNext()
        result = BinOp(value: "/", children: [result, parseFactor(symbolTable: symbolTable)])
      }
    }
    return result
  }

  private func parseExpression(symbolTable: SymbolTable) -> Node {
    var result = parseTerm(symbolTable: symbolTable)
    while tokenizer.next.type == "PLUS" || tokenizer.next.type == "MINUS" {
      if tokenizer.next.type == "PLUS" {
        tokenizer.selectNext()
        result = BinOp(value: "+", children: [result, parseTerm(symbolTable: symbolTable)])
      } else if tokenizer.next.type == "MINUS" {
        tokenizer.selectNext()
        result = BinOp(value: "-", children: [result, parseTerm(symbolTable: symbolTable)])
      }
    }
    return result
  }

  private func parsePrint(symbolTable: SymbolTable) -> Node {
    tokenizer.selectNext()
    if tokenizer.next.type != "LPAREN" {
      writeStderrAndExit("Missing opening parenthesis for print statement")
    }
    tokenizer.selectNext()
    let printValue = parseExpression(symbolTable: symbolTable).evaluate()
    if tokenizer.next.type != "RPAREN" {
      writeStderrAndExit("Missing closing parenthesis for print statement")
    }
    tokenizer.selectNext()
    print(printValue)
    return NoOp(value: "", children: [])
  }

  private func parseAssignment(symbolTable: SymbolTable) -> Node {
    let variableName = String(tokenizer.next.keyword)
    tokenizer.selectNext()
    if tokenizer.next.type != "ASSIGN" {
      writeStderrAndExit("Missing assignment operator")
    }
    tokenizer.selectNext()
    let variableValue = parseExpression(symbolTable: symbolTable).evaluate()
    symbolTable.setValue(variableName, variableValue)
    return NoOp(value: "", children: [])
  }

  private func parseStatement(symbolTable: SymbolTable) -> Node {
    if tokenizer.next.type == "IDENTIFIER" {
      return parseAssignment(symbolTable: symbolTable)
    } else if tokenizer.next.type == "PRINT" {
      return parsePrint(symbolTable: symbolTable)
    } else if tokenizer.next.type == "EOL" {
      tokenizer.selectNext()
      return NoOp(value: "", children: [])
    } else {
      writeStderrAndExit("Invalid statement")
      return NoOp(value: "", children: [])
    }
  }

  private func parseBlock(symbolTable: SymbolTable) -> Node {
    var statements: [Node] = []
    while tokenizer.next.type != "EOF" {
      let statement = parseStatement(symbolTable: symbolTable)
      statements.append(statement)
    }
    return NoOp(value: "", children: statements)
  }

  public func run(code: String, symbolTable: SymbolTable) -> Node {
    let filteredCode = PrePro.filter(code: code)
    self.tokenizer = Tokenizer(source: filteredCode)
    tokenizer.selectNext() // Position the tokenizer to the first token
    return parseBlock(symbolTable: symbolTable)
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
let symbolTable = SymbolTable()
let myParser = Parser()
let ast = myParser.run(code: fileContent, symbolTable: symbolTable)
let result = ast.evaluate()

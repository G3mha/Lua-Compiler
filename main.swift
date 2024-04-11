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
    if self.value == "PLUS" {
      return self.children[0].evaluate() + self.children[1].evaluate()
    } else if self.value == "MINUS" {
      return self.children[0].evaluate() - self.children[1].evaluate()
    } else if self.value == "MUL" {
      return self.children[0].evaluate() * self.children[1].evaluate()
    } else if self.value == "DIV" {
      return self.children[0].evaluate() / self.children[1].evaluate()
    } else if self.value == "OR" {
      return self.children[0].evaluate() || self.children[1].evaluate()
    } else if self.value == "AND" {
      return self.children[0].evaluate() && self.children[1].evaluate()
    } else if self.value == "EQ" {
      return self.children[0].evaluate() == self.children[1].evaluate()
    } else if self.value == "GT" {
      return self.children[0].evaluate() > self.children[1].evaluate()
    } else if self.value == "LT" {
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
    if self.value == "PLUS" {
      return self.children[0].evaluate()
    } else if self.value == "MINUS" {
      return -self.children[0].evaluate()
    } else if self.value == "NOT" {
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
      } else if char == ">" {
        self.next = Token(type: "GT", value: 0)
      } else if char == "<" {
        self.next = Token(type: "LT", value: 0)
      } else if char == "=" {
        if source[source.index(source.startIndex, offsetBy: position + 1)] == "=" {
          self.next = Token(type: "EQ", value: 0)
          position += 1
        } else {
          self.next = Token(type: "ASSIGN", value: 0)
        }
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
        if ["print", "if", "else", "while", "do", "then", "end", "and", "or", "not", "read"].contains(variableString) ==  {
          self.next = Token(type: variableString.uppercased(), value: 0)
        } if variableString == "true" {
          self.next = Token(type: "NUMBER", value: 1)
        } if variableString == "false" {
          self.next = Token(type: "NUMBER", value: 0)
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
    } else if tokenizer.next.type == "IDENTIFIER" {
      let variableName = String(tokenizer.next.keyword)
      let variableValue = symbolTable.getValue(variableName)
      result = IntVal(value: String(variableValue), children: [])
    } else if ["NOT", "MINUS", "PLUS"].contains(tokenizer.next.type) {
      result = UnOp(value: tokenizer.next.type, children: [parseFactor(symbolTable: symbolTable)])
    } else if tokenizer.next.type == "LPAREN" {
      tokenizer.selectNext()
      result = parseBoolExpression(symbolTable: symbolTable)
      if tokenizer.next.type != "RPAREN" {
        writeStderrAndExit("Missing closing parenthesis")
      }
      tokenizer.selectNext()
    } else if tokenizer.next.type == "READ" {
      tokenizer.selectNext()
      if tokenizer.next.type != "LPAREN" {
        writeStderrAndExit("Missing opening parenthesis for read statement")
      }
      tokenizer.selectNext()
      if tokenizer.next.type != "RPAREN" {
        writeStderrAndExit("Missing closing parenthesis for read statement")
      }
      // Read line from stdin, then cast to Int and set as value
      // should only accept Numbers and Bools
      let input = readLine()
      guard let intValue = Int(input ?? "") else {
        if input == "true" {
          result = IntVal(value: "1", children: [])
        } else if input == "false" {
          result = IntVal(value: "0", children: [])
        } else {
          writeStderrAndExit("Read value could not cast String to Int")
        }
      }
    } else {
      writeStderrAndExit("Invalid input")
    }
    tokenizer.selectNext()
    return result
  }

  private func parseTerm(symbolTable: SymbolTable) -> Node {
    var result = parseFactor(symbolTable: symbolTable)
    while tokenizer.next.type == "MUL" || tokenizer.next.type == "DIV" {
      tokenizer.selectNext()
      result = BinOp(value: tokenizer.next.type, children: [result, parseFactor(symbolTable: symbolTable)])
    }
    return result
  }

  private func parseExpression(symbolTable: SymbolTable) -> Node {
    var result = parseTerm(symbolTable: symbolTable)
    while tokenizer.next.type == "PLUS" || tokenizer.next.type == "MINUS" {
      tokenizer.selectNext()
      result = BinOp(value: tokenizer.next.type, children: [result, parseTerm(symbolTable: symbolTable)])
    }
    return result
  }

  private func parseRelationalExpression(symbolTable: SymbolTable) -> Node {
    var result = parseExpression(symbolTable: symbolTable)
    while tokenizer.next.type == "GT" || tokenizer.next.type == "LT" || tokenizer.next.type == "EQ" {
      tokenizer.selectNext()
      result = BinOp(value: tokenizer.next.type, children: [result, parseExpression(symbolTable: symbolTable)])
    }
    return result
  }

  private func parseBooleanTerm(symbolTable: SymbolTable) -> Node {
    var result = parseRelationalExpression(symbolTable: symbolTable)
    while tokenizer.next.type == "AND" {
      tokenizer.selectNext()
      result = BinOp(value: tokenizer.next.type, children: [result, parseRelationalExpression(symbolTable: symbolTable)])
    }
    return result
  }

  private func parseBoolExpression(symbolTable: SymbolTable) -> Node {
    var result = parseBooleanTerm(symbolTable: symbolTable)
    while tokenizer.next.type == "OR" {
      tokenizer.selectNext()
      result = BinOp(value: tokenizer.next.type, children: [result, parseBooleanTerm(symbolTable: symbolTable)])
    }
    return result
  }

  private func parseIf(symbolTable: SymbolTable) -> Node {
    tokenizer.selectNext()
    let condition = parseBoolExpression(symbolTable: symbolTable).evaluate()
    if tokenizer.next.type != "THEN" {
      writeStderrAndExit("Missing THEN keyword for if statement")
    }
    tokenizer.selectNext()
    if tokenizer.next.type != "EOL" {
      writeStderrAndExit("Missing EOL after THEN keyword")
    }
    var statements: [Node] = []
    if condition == 1 {
      while tokenizer.next.type != "END" {
        let statement = parseStatement(symbolTable: symbolTable)
        statements.append(statement)
      }
    } else {
      while !["END", "ELSE"].contains(tokenizer.next.type) {
        tokenizer.selectNext()
      }
      if tokenizer.next.type == "ELSE" {
        tokenizer.selectNext()
        if tokenizer.next.type != "EOL" {
          writeStderrAndExit("Missing EOL after ELSE keyword")
        }
        while tokenizer.next.type != "END" {
          let statement = parseStatement(symbolTable: symbolTable)
          statements.append(statement)
        }
      }
      tokenizer.selectNext()
    }
    return NoOp(value: "", children: statements)
  }

  private func parseWhile(symbolTable: SymbolTable) -> Node {
    tokenizer.selectNext()
    let condition = parseBoolExpression(symbolTable: symbolTable).evaluate()
    if tokenizer.next.type != "DO" {
      writeStderrAndExit("Missing DO keyword for while statement")
    }
    tokenizer.selectNext()
    if tokenizer.next.type != "EOL" {
      writeStderrAndExit("Missing EOL after DO keyword")
    }
    var statements: [Node] = []
    while condition == 1 {
      while tokenizer.next.type != "END" {
        let statement = parseStatement(symbolTable: symbolTable)
        statements.append(statement)
      }
    }
    tokenizer.selectNext()
    return NoOp(value: "", children: statements)
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
    } else if tokenizer.next.type == "WHILE" {
      tokenizer.selectNext()
      // TODO: Implement while loop
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

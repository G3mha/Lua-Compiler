import Foundation

func writeStderrAndExit(_ message: String) {
  // function that writes to stderr a received string and exits with error
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
      return ((self.children[0].evaluate() != 0) || (self.children[1].evaluate() != 0)) ? 1 : 0
    } else if self.value == "AND" {
      return ((self.children[0].evaluate() != 0) && (self.children[1].evaluate() != 0)) ? 1 : 0
    } else if self.value == "EQ" {
      return (self.children[0].evaluate() == self.children[1].evaluate()) ? 1 : 0
    } else if self.value == "GT" {
      return (self.children[0].evaluate() > self.children[1].evaluate()) ? 1 : 0
    } else if self.value == "LT" {
      return (self.children[0].evaluate() < self.children[1].evaluate()) ? 1 : 0
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
      return (self.children[0].evaluate() == 0) ? 1 : 0
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
    if variables[variable] == nil {
      writeStderrAndExit("Variable not found in SymbolTable: \(variable)")
    }
    return variables[variable]!
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
      var tokenWord = source[position]
      if tokenWord == "+" {
        self.next = Token(type: "PLUS", value: "0")
      } else if tokenWord == "-" {
        self.next = Token(type: "MINUS", value: "0")
      } else if tokenWord == "*" {
        self.next = Token(type: "MUL", value: "0")
      } else if tokenWord == "/" {
        self.next = Token(type: "DIV", value: "0")
      } else if tokenWord == "(" {
        self.next = Token(type: "LPAREN", value: "0")
      } else if tokenWord == ")" {
        self.next = Token(type: "RPAREN", value: "0")
      } else if tokenWord == ">" {
        self.next = Token(type: "GT", value: "0")
      } else if tokenWord == "<" {
        self.next = Token(type: "LT", value: "0")
      } else if tokenWord == "=" {
        if source[position + 1] == "=" {
          self.next = Token(type: "EQ", value: "0")
          position += 1
        } else {
          self.next = Token(type: "ASSIGN", value: "0")
        }
      } else if tokenWord == "\n" {
        self.next = Token(type: "EOL", value: "0")
      } else if tokenWord.isNumber {
        while position < source.count {
          let nextChar = source[position]
          if nextChar.isNumber {
            tokenWord += nextChar
          } else {
            break
          }
          position += 1
        }
        position -= 1
        self.next = Token(type: "NUMBER", value: numberString)
      } else if tokenWord.isLetter {
        while position < source.count {
          let nextChar = source[position]
          if nextChar.isLetter || nextChar.isNumber || nextChar == "_" {
            tokenWord += nextChar
          } else {
            break
          }
          position += 1
        }
        position -= 1
        if ["print", "if", "else", "while", "do", "then", "end", "and", "or", "not", "read"].contains(tokenWord) {
          self.next = Token(type: tokenWord.uppercased(), value: "0")
        } else if tokenWord == "true" || tokenWord == "false" {
          self.next = Token(type: "NUMBER", value: tokenWord == "true" ? "1" : "0")
        } else {
          self.next = Token(type: "IDENTIFIER", value: tokenWord)
        }
      } else {
        writeStderrAndExit("Invalid character \(char)")
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
    var result: Node = NoOp(value: "", children: [])
    if tokenizer.next.type == "NUMBER" {
      result = IntVal(value: String(tokenizer.next.value), children: [])
      tokenizer.selectNext()
    } else if tokenizer.next.type == "IDENTIFIER" {
      let variableName = String(tokenizer.next.value)
      let variableValue = symbolTable.getValue(variableName)
      result = IntVal(value: String(variableValue), children: [])
      tokenizer.selectNext()
    } else if ["NOT", "MINUS", "PLUS"].contains(tokenizer.next.type) {
      tokenizer.selectNext()
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
      let input = readLine()
      if input == "true" {
        result = IntVal(value: "1", children: [])
      } else if input == "false" {
        result = IntVal(value: "0", children: [])
      // Try to cast input to Int, if it fails, print error and exit
      } else if let inputInt = Int(input ?? "") {
        result = IntVal(value: String(inputInt), children: [])
      } else {
        writeStderrAndExit("Read value could not cast String to Int")
      }
    } else {
      writeStderrAndExit("Invalid input")
    }
    return result
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
    while tokenizer.next.type == "PLUS" || tokenizer.next.type == "MINUS" {
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

  private func parseIf(symbolTable: SymbolTable) -> Node {
    let condition = parseBoolExpression(symbolTable: symbolTable).evaluate()
    if tokenizer.next.type == "THEN" {
      tokenizer.selectNext()
      if tokenizer.next.type == "EOL" {
        tokenizer.selectNext()
        var statements: [Node] = []
        while tokenizer.next.type != "END" && tokenizer.next.type != "ELSE" {
          if condition == 1 {
            let statement = parseStatement(symbolTable: symbolTable)
            statements.append(statement)
          } else {
            tokenizer.selectNext()
          }
        }
        if tokenizer.next.type == "ELSE" {
          tokenizer.selectNext()
          while tokenizer.next.type != "END" {
            if condition == 0 {
              let statement = parseStatement(symbolTable: symbolTable)
              statements.append(statement)
            } else {
              tokenizer.selectNext()
            }
          }
        }
        if tokenizer.next.type == "END" {
          tokenizer.selectNext()
          return NoOp(value: "", children: statements)
        } else {
          writeStderrAndExit("Missing END after IF statement")
        }
      } else {
        writeStderrAndExit("Missing EOL after THEN")
      }
    } else {
      writeStderrAndExit("Missing THEN within if statement")
    }
  }

  private func parseWhile(symbolTable: SymbolTable) -> Node {
    let condition = parseBoolExpression(symbolTable: symbolTable).evaluate()
    if tokenizer.next.type == "DO" {
      tokenizer.selectNext()
      if tokenizer.next.type == "EOL" {
        tokenizer.selectNext()
        var statements: [Node] = []
        while condition == 1 {
          while tokenizer.next.type != "END" {
            let statement = parseStatement(symbolTable: symbolTable)
            statements.append(statement)
          }
          condition = parseBoolExpression(symbolTable: symbolTable).evaluate()
        }
        if tokenizer.next.type == "END" {
          tokenizer.selectNext()
          return NoOp(value: "", children: statements)
        } else {
          writeStderrAndExit("Missing END after WHILE loop")
        }
      } else {
        writeStderrAndExit("Missing EOL after DO")
      }
    } else {
      writeStderrAndExit("Missing DO within while statement")
    }
  }

  private func parsePrint(symbolTable: SymbolTable) -> Node {
    if tokenizer.next.type == "LPAREN" {
      tokenizer.selectNext()
      let printValue = parseBoolExpression(symbolTable: symbolTable).evaluate()
      if tokenizer.next.type == "RPAREN" {
        tokenizer.selectNext()
        print(printValue)
        return NoOp(value: "", children: [])
      } else {
        writeStderrAndExit("Missing closing parenthesis for print statement")
      }
    } else {
      writeStderrAndExit("Missing opening parenthesis for print statement")
    }
  }

  private func parseAssignment(symbolTable: SymbolTable) -> Node {
    let variableName = String(tokenizer.next.value)
    tokenizer.selectNext()
    if tokenizer.next.type == "ASSIGN" {
      tokenizer.selectNext()
      let variableValue = parseBoolExpression(symbolTable: symbolTable).evaluate()
      symbolTable.setValue(variableName, variableValue)
      return NoOp(value: "", children: [])
    } else {
      writeStderrAndExit("Missing assignment operator")
    }
  }

  private func parseStatement(symbolTable: SymbolTable) -> Node {
    var result = NoOp(value: "", children: [])

    if tokenizer.next.type == "IDENTIFIER" {
      tokenizer.selectNext()
      result = parseAssignment(symbolTable: symbolTable)
    } else if tokenizer.next.type == "PRINT" {
      tokenizer.selectNext()
      result = parsePrint(symbolTable: symbolTable)
    } else if tokenizer.next.type == "WHILE" {
      tokenizer.selectNext()
      result = parseWhile(symbolTable: symbolTable)
    } else if tokenizer.next.type == "IF" {
      tokenizer.selectNext()
      result = parseIf(symbolTable: symbolTable)
    }
    
    if tokenizer.next.type == "EOL" {
      tokenizer.selectNext()
      return result
    } else {
      writeStderrAndExit("Missing EOL")
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

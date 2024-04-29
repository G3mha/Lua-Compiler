import Foundation

func writeStderrAndExit(_ message: String) {
  // function that writes to stderr a received string and exits with error
  fputs("ERROR: \(message)\n", stderr) // write to stderr
  exit(1) // exit with error
}

class PrePro {
  static public func filter(code: String) -> String {
    let splittedCode = code.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "\t", with: "").split(separator: "\n")
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

enum EvalResult {
  case integer(Int)
  case string(String)
}

protocol Node {
  var value: String { get set }
  var children: [Node] { get set }
  func evaluate() -> EvalResult
}

class BinOp: Node {
  var value: String
  var children: [Node]

  init(value: String, children: [Node]) {
    self.value = value
    self.children = children
  }

  func evaluate() -> EvalResult {
    let firstValue = self.children[0].evaluate()
    let secondValue = self.children[1].evaluate()
    
    switch (firstResult, secondResult) {
      case let (.integer(firstVal), .integer(secondVal)):
        switch self.value {
          case "PLUS":
            return .integer(firstVal + secondVal)
          case "MINUS":
            return .integer(firstVal - secondVal)
          case "MUL":
            return .integer(firstVal * secondVal)
          case "DIV":
            return .integer(firstVal / secondVal)
          case "GT":
            return .integer((firstVal > secondVal) ? 1 : 0)
          case "LT":
            return .integer((firstVal < secondVal) ? 1 : 0)
          default:
            return .integer(0)
        }
      case let (.string(firstStr), .string(secondStr)):
        if self.value == "CONCAT" {
          return .string(firstStr + secondStr)
        } else {
          writeStderrAndExit("Unsupported operation on strings")
        }
      default:
        writeStderrAndExit("Type mismatch in binary operation")
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

  func evaluate() {
    let value = self.children[0].evaluate()

    if self.value == "NOT" {
      return (value == 0) ? 1 : 0
    }

    if value is String {
      writeStderrAndExit("Cannot perform unary arithmetic operations on Strings")
    } 
    
    if self.value == "PLUS" {
      return value
    } else if self.value == "MINUS" {
      return -value
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

  func evaluate() {
    if let intValue = Int(self.value) {
      return intValue
    } else {
      writeStderrAndExit("IntVal value could not cast String to Int")
    }
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

  func evaluate() {
    return self.value
  }
}

class NoOp: Node {
  var value: String
  var children: [Node]

  init(value: String, children: [Node]) {
    self.value = value
    self.children = children
  }

  func evaluate() {
    return 0
  }
}

enum VariableTypes {
  case integer(Int)
  case string(String)
}

class SymbolTable {
  private var variables: [String: VariableTypes] = [:]

  func initVar(_ variable: String) {
    variables[variable] = .integer(0)
  }

  func setValue(_ variable: String, _ value: VariableTypes) {
    guard variables.keys.contains(variable) else {
      writeStderrAndExit("Attempt to set an uninitialized variable: \(variable)")
      return
    }
    variables[variable] = value
  }

  func getValue(_ variable: String) -> VariableTypes? {
    guard let value = variables[variable] else {
      writeStderrAndExit("Variable not found in SymbolTable: \(variable)")
      return nil
    }
    return value
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
      let char = source[source.index(source.startIndex, offsetBy: position)]
      var tokenWord = ""
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
        while position < source.count {
          let nextChar = source[source.index(source.startIndex, offsetBy: position)]
          if nextChar == "\"" {
            break
          } else {
            tokenWord += String(nextChar)
          }
          position += 1
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
          if ["print", "if", "else", "while", "do", "then", "end", "and", "or", "not", "read", "true", "false"].contains(tokenWord) {
            break
          } else if nextChar.isLetter || nextChar.isNumber || nextChar == "_" {
            tokenWord += String(nextChar)
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
    } else if tokenizer.next.type == "IDENTIFIER" {
      let variableName = tokenizer.next.value
      let variableValue = symbolTable.getValue(variableName)
      tokenizer.selectNext()
      return IntVal(value: String(variableValue), children: [])
    } else if tokenizer.next.type == "PLUS" || tokenizer.next.type == "MINUS" || tokenizer.next.type == "NOT" {
      let operatorType = tokenizer.next.type
      tokenizer.selectNext()
      return UnOp(value: operatorType, children: [parseFactor(symbolTable: symbolTable)])
    } else if tokenizer.next.type == "LPAREN" {
      tokenizer.selectNext()
      let result = parseBoolExpression(symbolTable: symbolTable)
      if tokenizer.next.type == "RPAREN" {
        tokenizer.selectNext()
        return result
      } else {
        writeStderrAndExit("Missing closing parenthesis")
      }
    } else if tokenizer.next.type == "READ" {
      tokenizer.selectNext()
      if tokenizer.next.type == "LPAREN" {
        tokenizer.selectNext()
        if tokenizer.next.type == "RPAREN" {
          tokenizer.selectNext()
          // Read line from stdin, then cast to Int and set as value
          let input = readLine()
          if input == "true" {
            return IntVal(value: "1", children: [])
          } else if input == "false" {
            return IntVal(value: "0", children: [])
          // Try to cast input to Int, if it fails, print error and exit
          } else if let inputInt = Int(input ?? "") {
            return IntVal(value: String(inputInt), children: [])
          } else {
            writeStderrAndExit("Read value could not cast String to Int")
          }
        } else {
          writeStderrAndExit("Missing closing parenthesis for read statement")
        }
      } else {
        writeStderrAndExit("Missing opening parenthesis for read statement")
      }
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
    return NoOp(value: "", children: [])
  }

  private func parseWhile(symbolTable: SymbolTable) -> Node {
    let whileStartPosition = tokenizer.position-1
    var whileEndPosition = tokenizer.position-1
    var conditionValue = parseBoolExpression(symbolTable: symbolTable).evaluate()
    var statements: [Node] = []
    while conditionValue == 1 {
      if tokenizer.next.type == "DO" {
        tokenizer.selectNext()
        if tokenizer.next.type == "EOL" {
          tokenizer.selectNext()
          while tokenizer.next.type != "END" {
            let statement = parseStatement(symbolTable: symbolTable)
            statements.append(statement)
          }
          if tokenizer.next.type == "END" {
            whileEndPosition = tokenizer.position
            tokenizer.position = whileStartPosition
            tokenizer.selectNext()
            conditionValue = parseBoolExpression(symbolTable: symbolTable).evaluate()
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
    tokenizer.position = whileEndPosition
    tokenizer.selectNext()
    return NoOp(value: "", children: statements)
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
    return NoOp(value: "", children: [])
  }

  private func parseDeclaration(symbolTable: SymbolTable) -> Node {
    if tokenizer.next.type == "IDENTIFIER" {
      let variableName = tokenizer.next.value
      symbolTable.initVar(variableName)
      tokenizer.selectNext()
      if tokenizer.next.type == "ASSIGN" {
        tokenizer.selectNext()
        let variableValue = parseBoolExpression(symbolTable: symbolTable).evaluate()
        if tokenizer.next.type == "STRING" {
          symbolTable.setValue(variableName, .string(variableValue))
          tokenizer.selectNext()
        } else if tokenizer.next.type == "NUMBER" {
          symbolTable.setValue(variableName, .integer(variableValue))
          tokenizer.selectNext()
        } else {
          writeStderrAndExit("Invalid variable value in declaration")
        }
      }
    } else {
      writeStderrAndExit("Invalid variable name in declaration")
    }
    return NoOp(value: "", children: [])
  }

  private func parseAssignment(symbolTable: SymbolTable, variableName: String) -> Node {
    if tokenizer.next.type == "ASSIGN" {
      tokenizer.selectNext()
      let variableValue = parseBoolExpression(symbolTable: symbolTable).evaluate()
      symbolTable.setValue(variableName, variableValue)
      return NoOp(value: "", children: [])
    } else {
      writeStderrAndExit("Missing assignment operator")
    }
    return NoOp(value: "", children: [])
  }

  private func parseStatement(symbolTable: SymbolTable) -> Node {
    if tokenizer.next.type == "IDENTIFIER" {
      let variableName = tokenizer.next.value
      tokenizer.selectNext()
      return parseAssignment(symbolTable: symbolTable, variableName: variableName)
    } else if tokenizer.next.type == "DECLARATION" {
      tokenizer.selectNext()
      return parseDeclaration(symbolTable: symbolTable)
    } else if tokenizer.next.type == "PRINT" {
      tokenizer.selectNext()
      return parsePrint(symbolTable: symbolTable)
    } else if tokenizer.next.type == "WHILE" {
      tokenizer.selectNext()
      let result = parseWhile(symbolTable: symbolTable)
      if tokenizer.next.type == "EOL" {
        tokenizer.selectNext()
        return result
      } else {
        writeStderrAndExit("Unexpected token after END in WHILE statement")
      }
    } else if tokenizer.next.type == "IF" {
      tokenizer.selectNext()
      let result = parseIf(symbolTable: symbolTable)
      if tokenizer.next.type == "EOL" {
        tokenizer.selectNext()
        return result
      } else {
        writeStderrAndExit("Unexpected token after END in IF statement")
      }
    } else if tokenizer.next.type == "EOL" {
      tokenizer.selectNext()
      return NoOp(value: "", children: [])
    } else {
      writeStderrAndExit("Invalid statement")
    }
    return NoOp(value: "", children: [])
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

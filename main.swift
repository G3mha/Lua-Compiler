import Foundation

// function that writes to stderr a received string and exits with error
func writeStderrAndExit(_ message: String) {
  fputs("ERROR: \(message)\n", stderr) // write to stderr
  exit(1) // exit with error
}

class PrePro {
  static private func remove_spaces(code: String) -> String {
    for i in 0..<code.count {
      let char = code[code.index(code.startIndex, offsetBy: i)]
      if char == " " {
        var j = i
        while j >= 0 && code[code.index(code.startIndex, offsetBy: j)] == " " {
          j -= 1
        }
        let charJ = code[code.index(code.startIndex, offsetBy: j)]

        var k = i
        while k < code.count && code[code.index(code.startIndex, offsetBy: k)] == " " {
          k += 1
        }
        let charK = code[code.index(code.startIndex, offsetBy: k)]

        if charJ.isNumber && charK.isNumber {
          writeStderrAndExit("Missing operator")
        }
      }
    }
    return code.replacingOccurrences(of: " ", with: "")
  }

  static public func filter(code: String) -> String {
    let trimmedCode = code.trimmingCharacters(in: .whitespacesAndNewlines)
    var processedCode = ""
    if trimmedCode.contains("--") {
      // split the string by "--" and get the first element
      processedCode = String(trimmedCode.split(separator: "--")[0])
    } else {
      processedCode = String(trimmedCode)
    }
    processedCode = remove_spaces(code: processedCode)
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

  func evaluate() -> Int {
    return 0
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
    if tokenizer.next.type == "EOF" {
      writeStderrAndExit("Empty input")
    }
    if tokenizer.next.type == "DIV" || tokenizer.next.type == "MUL" {
      writeStderrAndExit("First number missing")
    }
    if tokenizer.next.type == "RPAREN" {
      writeStderrAndExit("Missing opening parenthesis")
    }
    let endOfParsing = parseExpression()
    if tokenizer.next.type != "EOF" {
      writeStderrAndExit("Not all tokens were consumed")
    }
    return endOfParsing
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
}

func readFile(_ path: String) -> String? {
  do {
    let contents = try String(contentsOfFile: path, encoding: .utf8)
    return contents
  } catch {
    print("Error reading file: \(error)")
    return nil
  }
}

let filePath = CommandLine.arguments[1]
if let fileContents = readFile(filePath) {
  let myParser = Parser()
  let ast = myParser.run(code: fileContents)
  let result = ast.evaluate()
  print(result)
} else {
  writeStderrAndExit("Failed to read file")
}

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
      if self.next.type == "PLUS" || self.next.type == "MINUS" || self.next.type == "DIV" || self.next.type == "MUL" || self.next.type == "LPAREN" {
        writeStderrAndExit("Last value missing")
      }
      self.next = Token(type: "EOF", value: 0)
    }
  }
}

class Parser {
  var tokenizer: Tokenizer

  init() {
    self.tokenizer = Tokenizer(source: "")
  }

  func run(code: String) -> Void {
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
    print(endOfParsing)
  }

  func parseFactor() -> Int {
    var result = 0
    if tokenizer.next.type == "NUMBER" {
      result = tokenizer.next.value
      tokenizer.selectNext()
    } else if tokenizer.next.type == "PLUS" {
      tokenizer.selectNext()
      result = parseFactor()
    } else if tokenizer.next.type == "MINUS" {
      tokenizer.selectNext()
      result = -parseFactor()
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

  func parseTerm() -> Int {
    var result = parseFactor()
    while tokenizer.next.type == "MUL" || tokenizer.next.type == "DIV" {
      if tokenizer.next.type == "MUL" {
        tokenizer.selectNext()
        result *= parseFactor()
      } else if tokenizer.next.type == "DIV" {
        tokenizer.selectNext()
        result /= parseFactor()
      }
    }
    return result
  }

  func parseExpression() -> Int {
    var result = parseTerm()
    while tokenizer.next.type == "PLUS" || tokenizer.next.type == "MINUS" {
      if tokenizer.next.type == "PLUS" {
        tokenizer.selectNext()
        result += parseTerm()
      } else if tokenizer.next.type == "MINUS" {
        tokenizer.selectNext()
        result -= parseTerm()
      }
    }
    return result
  }
}


let myParser = Parser()
myParser.run(code: CommandLine.arguments[1])
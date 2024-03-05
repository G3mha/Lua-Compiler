import Foundation

// function that writes to stderr a received string and exits with error
func writeStderrAndExit(_ message: String) {
  fputs("ERROR: \(message)\n", stderr) // print to stderr
  exit(1) // exit with error
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
    // check if there's any PLUS, MINUS, DIV or MUL in the `code`
    if !code.contains("+") && !code.contains("-") && !code.contains("*") && !code.contains("/") {
      // split `code` by spaces and check how many elements there are
      let splitCode = code.split(separator: " ")
      // if `splitCode.count` is not 1, then there's an error
      if splitCode.count != 1 {
        writeStderrAndExit("No operators")
      }
      // check for chars that are unwanted, like ',' or '.'
      if code.contains(",") || code.contains(".") {
        writeStderrAndExit("Invalid character")
      }
    }
    let cleanCode = code.replacingOccurrences(of: " ", with: "")
    self.tokenizer = Tokenizer(source: cleanCode)
    tokenizer.selectNext() // Position the tokenizer to the first token
    if tokenizer.next.type == "EOF" {
      writeStderrAndExit("Empty input")
    }
    if tokenizer.next.type == "DIV" || tokenizer.next.type == "MUL" {
      writeStderrAndExit("First value missing")
    }
    if tokenizer.next.type == "RPAREN" {
      writeStderrAndExit("No opening parenthesis")
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
    while tokenizer.next.type == "MUL" || tokenizer.next.type == "DIV" || tokenizer.next.type == "LPAREN" {
      if tokenizer.next.type == "MUL" {
        tokenizer.selectNext()
        result *= parseTerm()
      } else if tokenizer.next.type == "DIV" {
        tokenizer.selectNext()
        result /= parseTerm()
      } else if tokenizer.next.type == "LPAREN" {
        tokenizer.selectNext()
        result = parseExpression()
        if tokenizer.next.type != "RPAREN" {
          writeStderrAndExit("Missing closing parenthesis")
        }
        tokenizer.selectNext()
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
        if tokenizer.next.type == "PLUS" { // Check next token directly, not next.next
          tokenizer.selectNext()
          tokenizer.selectNext()
          result -= parseTerm()
        } else {
          tokenizer.selectNext()
          result -= parseTerm()
        }
      }
    }
    return result
  }
}


let myParser = Parser()
// Run the Parser
myParser.run(code: CommandLine.arguments[1])
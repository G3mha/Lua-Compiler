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
      if char == "+" || char == "-" {
        if self.next.type == "PLUS" || self.next.type == "MINUS" {
          writeStderrAndExit("Double operators")
        }
      }
      if char == "+" {
        self.next = Token(type: "PLUS", value: 0)
      } else if char == "-" {
        self.next = Token(type: "MINUS", value: 0)
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
      if self.next.type == "PLUS" || self.next.type == "MINUS" {
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

  func parseExpression() -> Int {
    var result = 0
    if tokenizer.next.type == "NUMBER" {
      result = tokenizer.next.value
      tokenizer.selectNext()
    }
    while tokenizer.next.type == "PLUS" || tokenizer.next.type == "MINUS" {
      if tokenizer.next.type == "PLUS" {
        tokenizer.selectNext()
        result += tokenizer.next.value
      } else if tokenizer.next.type == "MINUS" {
        tokenizer.selectNext()
        result -= tokenizer.next.value
      }
      tokenizer.selectNext()
    }
    return result
  }

  func run(code: String) -> Void {
    let cleanCode = code.replacingOccurrences(of: " ", with: "")
    self.tokenizer = Tokenizer(source: cleanCode)
    tokenizer.selectNext() // Position the tokenizer to the first token
    if tokenizer.next.type == "EOF" {
      writeStderrAndExit("Empty input")
    }
    if tokenizer.next.type == "PLUS" || tokenizer.next.type == "MINUS" {
      writeStderrAndExit("First value missing")
    }
    let endOfParsing = parseExpression()
    if tokenizer.next.type == "EOF" {
      print(endOfParsing)
    } else {
      writeStderrAndExit("Syntax Error")
    }
  }
}

let myParser = Parser()
// Run the Parser
myParser.run(code: CommandLine.arguments[1])
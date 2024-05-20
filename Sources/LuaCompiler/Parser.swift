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
      let variableName = tokenizer.next.value
      let variableValue = symbolTable.getValue(variableName)
      tokenizer.selectNext()
      if let value = variableValue {
        switch value {
          case .integer(let intValue):
            return IntVal(value: String(intValue), children: [])
          case .string(let strValue):
            return StringVal(value: strValue, children: [])
          case .nilValue:
            writeStderrAndExit("Variable \(variableName) is initialized, but has no value assigned")
        }
      } else {
        writeStderrAndExit("Variable \(variableName) not found in symbol table")
      }
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
    let condition = parseBoolExpression(symbolTable: symbolTable).evaluate(symbolTable: symbolTable)
    if tokenizer.next.type == "THEN" {
      tokenizer.selectNext()
      if tokenizer.next.type == "EOL" {
        tokenizer.selectNext()
        var statements: [Node] = []
        while tokenizer.next.type != "END" && tokenizer.next.type != "ELSE" {
          if getIntFromEvalResult(condition) == 1 {
            let statement = parseStatement(symbolTable: symbolTable)
            statements.append(statement)
          } else {
            tokenizer.selectNext()
          }
        }
        if tokenizer.next.type == "ELSE" {
          tokenizer.selectNext()
          while tokenizer.next.type != "END" {
            if getIntFromEvalResult(condition) == 0 {
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
    var conditionValue = parseBoolExpression(symbolTable: symbolTable).evaluate(symbolTable: symbolTable)
    
    var statements: [Node] = []

    while getIntFromEvalResult(conditionValue) == 1 {
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
            conditionValue = parseBoolExpression(symbolTable: symbolTable).evaluate(symbolTable: symbolTable)
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
      let printValue = parseBoolExpression(symbolTable: symbolTable).evaluate(symbolTable: symbolTable)
      if tokenizer.next.type == "RPAREN" {
        tokenizer.selectNext()
        switch printValue {
          case .integer(let intValue):
            print(intValue)
          case .string(let stringValue):
            print(stringValue)
        }
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
      // Get the variable name
      let variableName = tokenizer.next.value
      tokenizer.selectNext()
      
      // Check if there's an assignment
      if tokenizer.next.type == "ASSIGN" {
        tokenizer.selectNext()
        // Parse the expression to initialize the variable
        let expression = parseBoolExpression(symbolTable: symbolTable)
        let variableValue = expression.evaluate(symbolTable: symbolTable)
        switch variableValue {
          case .integer(let intValue):
            symbolTable.initVar(variableName, .integer(intValue))
          case .string(let strValue):
            symbolTable.initVar(variableName, .string(strValue))
        }
        return NoOp(value: "", children: [])
      } else {
        // If no assignment, simply initialize the variable with default value
        symbolTable.initVar(variableName)
        return NoOp(value: "", children: [])
      }
    } else {
      writeStderrAndExit("Invalid variable name in declaration")
      return NoOp(value: "", children: [])
    }
  }


  private func parseAssignment(symbolTable: SymbolTable, variableName: String) -> Node {
    if tokenizer.next.type == "ASSIGN" {
      tokenizer.selectNext()
      let evalResult = parseBoolExpression(symbolTable: symbolTable).evaluate(symbolTable: symbolTable)
      let variableValue: VariableTypes
      switch evalResult {
        case .integer(let intValue):
          variableValue = .integer(intValue)
        case .string(let stringValue):
          variableValue = .string(stringValue)
      }

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
    } else if tokenizer.next.type == "LOCAL" {
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
    } else if tokenizer.next.type == "FUNCTION" {
      tokenizer.selectNext()
      if tokenizer.next.type == "IDENTIFIER" {
        let functionName = tokenizer.next.value
        tokenizer.selectNext()
        if tokenizer.next.type == "LPAREN" {
          tokenizer.selectNext()
          if tokenizer.next.type == "RPAREN" {
            tokenizer.selectNext()
            if tokenizer.next.type == "EOL" {
              tokenizer.selectNext()
              var statements: [Node] = []
              while tokenizer.next.type != "END" {
                let statement = parseStatement(symbolTable: symbolTable)
                statements.append(statement)
              }
              if tokenizer.next.type == "END" {
                tokenizer.selectNext()
                return NoOp(value: "", children: statements)
              } else {
                writeStderrAndExit("Missing END after FUNCTION statement")
              }
            } else {
              writeStderrAndExit("Missing EOL after function declaration")
            }
          } else {
            writeStderrAndExit("Missing closing parenthesis for function declaration")
          }
        } else {
          writeStderrAndExit("Missing opening parenthesis for function declaration")
        }
      } else {
        writeStderrAndExit("Invalid function name in function declaration")
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

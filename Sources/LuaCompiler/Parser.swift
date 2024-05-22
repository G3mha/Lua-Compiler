class Parser {
  var tokenizer: Tokenizer

  init() {
    self.tokenizer = Tokenizer(source: "")
  }

  private func parseFactor(symbolTable: SymbolTable, funcTable: FuncTable) -> Node {
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
        if let intValue = value as? Int {
          return IntVal(value: String(intValue), children: [])
        } else if let strValue = value as? String {
          return StringVal(value: strValue, children: [])
        } else {
          fatalError("Variable \(variableName) is initialized, but has no value assigned")
        }
      } else {
        fatalError("Variable \(variableName) not found in symbol table")
      }
    } else if tokenizer.next.type == "PLUS" || tokenizer.next.type == "MINUS" || tokenizer.next.type == "NOT" {
      let operatorType = tokenizer.next.type
      tokenizer.selectNext()
      return UnOp(value: operatorType, children: [parseFactor(symbolTable: symbolTable, funcTable: funcTable)])
    } else if tokenizer.next.type == "LPAREN" {
      tokenizer.selectNext()
      let result = parseBoolExpression(symbolTable: symbolTable, funcTable: funcTable)
      if tokenizer.next.type == "RPAREN" {
        tokenizer.selectNext()
        return result
      } else {
        fatalError("Missing closing parenthesis")
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
            fatalError("Read value could not cast String to Int")
          }
        } else {
          fatalError("Missing closing parenthesis for read statement")
        }
      } else {
        fatalError("Missing opening parenthesis for read statement")
      }
    } else {
      fatalError("Invalid factor: (\(tokenizer.next.type), \(tokenizer.next.value))")
    }
    return NoOp(value: "", children: [])
  }

  private func parseTerm(symbolTable: SymbolTable, funcTable: FuncTable) -> Node {
    var result = parseFactor(symbolTable: symbolTable, funcTable: funcTable)
    while tokenizer.next.type == "MUL" || tokenizer.next.type == "DIV" {
      let operatorType = tokenizer.next.type
      tokenizer.selectNext()
      result = BinOp(value: operatorType, children: [result, parseFactor(symbolTable: symbolTable, funcTable: funcTable)])
    }
    return result
  }

  private func parseExpression(symbolTable: SymbolTable, funcTable: FuncTable) -> Node {
    var result = parseTerm(symbolTable: symbolTable, funcTable: funcTable)
    while tokenizer.next.type == "PLUS" || tokenizer.next.type == "MINUS" || tokenizer.next.type == "CONCAT" {
      let operatorType = tokenizer.next.type
      tokenizer.selectNext()
      result = BinOp(value: operatorType, children: [result, parseTerm(symbolTable: symbolTable, funcTable: funcTable)])
    }
    return result
  }

  private func parseRelationalExpression(symbolTable: SymbolTable, funcTable: FuncTable) -> Node {
    var result = parseExpression(symbolTable: symbolTable, funcTable: funcTable)
    while tokenizer.next.type == "GT" || tokenizer.next.type == "LT" || tokenizer.next.type == "EQ" {
      let operatorType = tokenizer.next.type
      tokenizer.selectNext()
      result = BinOp(value: operatorType, children: [result, parseExpression(symbolTable: symbolTable, funcTable: funcTable)])
    }
    return result
  }

  private func parseBooleanTerm(symbolTable: SymbolTable, funcTable: FuncTable) -> Node {
    var result = parseRelationalExpression(symbolTable: symbolTable, funcTable: funcTable)
    while tokenizer.next.type == "AND" {
      let operatorType = tokenizer.next.type
      tokenizer.selectNext()
      result = BinOp(value: operatorType, children: [result, parseRelationalExpression(symbolTable: symbolTable, funcTable: funcTable)])
    }
    return result
  }

  private func parseBoolExpression(symbolTable: SymbolTable, funcTable: FuncTable) -> Node {
    var result = parseBooleanTerm(symbolTable: symbolTable, funcTable: funcTable)
    while tokenizer.next.type == "OR" {
      let operatorType = tokenizer.next.type
      tokenizer.selectNext()
      result = BinOp(value: operatorType, children: [result, parseBooleanTerm(symbolTable: symbolTable, funcTable: funcTable)])
    }
    return result
  }

  private func parseIf(symbolTable: SymbolTable, funcTable: FuncTable) -> Node {
    let condition = parseBoolExpression(symbolTable: symbolTable, funcTable: funcTable).evaluate(symbolTable: symbolTable, funcTable: funcTable) as! Int
    if tokenizer.next.type == "THEN" {
      tokenizer.selectNext()
      if tokenizer.next.type == "EOL" {
        tokenizer.selectNext()
        var statements: [Node] = []
        while tokenizer.next.type != "END" && tokenizer.next.type != "ELSE" {
          if condition == 1 {
            let statement = parseStatement(symbolTable: symbolTable, funcTable: funcTable)
            statements.append(statement)
          } else {
            tokenizer.selectNext()
          }
        }
        if tokenizer.next.type == "ELSE" {
          tokenizer.selectNext()
          while tokenizer.next.type != "END" {
            if condition == 0 {
              let statement = parseStatement(symbolTable: symbolTable, funcTable: funcTable)
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
          fatalError("Missing END after IF statement")
        }
      } else {
        fatalError("Missing EOL after THEN")
      }
    } else {
      fatalError("Missing THEN within if statement")
    }
    return NoOp(value: "", children: [])
  }

  private func parseWhile(symbolTable: SymbolTable, funcTable: FuncTable) -> Node {
    let whileStartPosition = tokenizer.position-1
    var whileEndPosition = tokenizer.position-1
    var conditionValue = parseBoolExpression(symbolTable: symbolTable, funcTable: funcTable).evaluate(symbolTable: symbolTable, funcTable: funcTable) as! Int
    
    var statements: [Node] = []

    while conditionValue == 1 {
      if tokenizer.next.type == "DO" {
        tokenizer.selectNext()
        if tokenizer.next.type == "EOL" {
          tokenizer.selectNext()
          while tokenizer.next.type != "END" {
            let statement = parseStatement(symbolTable: symbolTable, funcTable: funcTable)
            statements.append(statement)
          }
          if tokenizer.next.type == "END" {
            whileEndPosition = tokenizer.position
            tokenizer.position = whileStartPosition
            tokenizer.selectNext()
            conditionValue = parseBoolExpression(symbolTable: symbolTable, funcTable: funcTable).evaluate(symbolTable: symbolTable, funcTable: funcTable) as! Int
          } else {
            fatalError("Missing END after WHILE loop")
          }
        } else {
          fatalError("Missing EOL after DO")
        }
      } else {
        fatalError("Missing DO within while statement")
      }
    }
    tokenizer.position = whileEndPosition
    tokenizer.selectNext()
    return NoOp(value: "", children: statements)
  }

  private func parsePrint(symbolTable: SymbolTable, funcTable: FuncTable) -> Node {
    if tokenizer.next.type == "LPAREN" {
      tokenizer.selectNext()
      let printValue = parseBoolExpression(symbolTable: symbolTable, funcTable: funcTable).evaluate(symbolTable: symbolTable, funcTable: funcTable)
      if tokenizer.next.type == "RPAREN" {
        tokenizer.selectNext()
        print(printValue)
        return NoOp(value: "", children: [])
      } else {
        fatalError("Missing closing parenthesis for print statement")
      }
    } else {
      fatalError("Missing opening parenthesis for print statement")
    }
    return NoOp(value: "", children: [])
  }

  private func parseDeclaration(symbolTable: SymbolTable, funcTable: FuncTable) -> Node {
    if tokenizer.next.type == "IDENTIFIER" {
      let variableName = tokenizer.next.value
      tokenizer.selectNext()
      
      // Check if there's an assignment
      if tokenizer.next.type == "ASSIGN" {
        tokenizer.selectNext()
        // Parse the expression to initialize the variable
        let expression = parseBoolExpression(symbolTable: symbolTable, funcTable: funcTable)
        let variableValue = expression.evaluate(symbolTable: symbolTable, funcTable: funcTable)
        symbolTable.initVar(variableName, variableValue)
        return NoOp(value: "", children: [])
      } else {
        symbolTable.initVar(variableName)
        return NoOp(value: "", children: [])
      }
    } else {
      fatalError("Invalid variable name in declaration")
      return NoOp(value: "", children: [])
    }
  }

  private func parseAssignment(symbolTable: SymbolTable, funcTable: FuncTable, variableName: String) -> Node {
    if tokenizer.next.type == "ASSIGN" {
      tokenizer.selectNext()
      let variableValue = parseBoolExpression(symbolTable: symbolTable, funcTable: funcTable).evaluate(symbolTable: symbolTable, funcTable: funcTable)
      symbolTable.setValue(variableName, variableValue)
      return NoOp(value: "", children: [])
    } else {
      fatalError("Missing assignment operator")
    }
    return NoOp(value: "", children: [])
  }

  private func parseStatement(symbolTable: SymbolTable, funcTable: FuncTable) -> Node {
    if tokenizer.next.type == "IDENTIFIER" {
      let variableName = tokenizer.next.value
      tokenizer.selectNext()
      return parseAssignment(symbolTable: symbolTable, funcTable: funcTable, variableName: variableName)
    } else if tokenizer.next.type == "LOCAL" {
      tokenizer.selectNext()
      return parseDeclaration(symbolTable: symbolTable, funcTable: funcTable)
    } else if tokenizer.next.type == "PRINT" {
      tokenizer.selectNext()
      return parsePrint(symbolTable: symbolTable, funcTable: funcTable)
    } else if tokenizer.next.type == "WHILE" {
      tokenizer.selectNext()
      let result = parseWhile(symbolTable: symbolTable, funcTable: funcTable)
      if tokenizer.next.type == "EOL" {
        tokenizer.selectNext()
        return result
      } else {
        fatalError("Unexpected token after END in WHILE statement")
      }
    } else if tokenizer.next.type == "IF" {
      tokenizer.selectNext()
      let result = parseIf(symbolTable: symbolTable, funcTable: funcTable)
      if tokenizer.next.type == "EOL" {
        tokenizer.selectNext()
        return result
      } else {
        fatalError("Unexpected token after END in IF statement")
      }
    } else if tokenizer.next.type == "FUNCTION" {
      tokenizer.selectNext()
      if tokenizer.next.type != "IDENTIFIER" {
        fatalError("Invalid function name in function declaration")
      }
      let functionName = tokenizer.next.value
      
      tokenizer.selectNext()
      if tokenizer.next.type != "LPAREN" {
        fatalError("Missing opening parenthesis for function declaration")
      }
      
      tokenizer.selectNext()
      // Parse function arguments
      var arguments: [String] = []
      while tokenizer.next.type != "RPAREN" {
        if tokenizer.next.type == "IDENTIFIER" {
          arguments.append(tokenizer.next.value)
          tokenizer.selectNext()
          if tokenizer.next.type == "COMMA" {
          } else if tokenizer.next.type != "RPAREN" {
            fatalError("Missing comma between function arguments")
          }
        } else {
          fatalError("Invalid argument name in function declaration")
        }
      }
      if tokenizer.next.type != "RPAREN" {
        fatalError("Missing closing parenthesis for function declaration")
      }

      tokenizer.selectNext()
      if tokenizer.next.type != "EOL" {
        fatalError("Missing EOL after function arguments")
      }

      // Parse function body
      var statements: [Node] = []
      while tokenizer.next.type != "END" {
        let statement = parseStatement(symbolTable: symbolTable, funcTable: funcTable)
        statements.append(statement)
      }
      if tokenizer.next.type != "END" {
        fatalError("Missing END after function declaration")
      }

      tokenizer.selectNext()
      funcTable.setFunction(functionName, arguments, statements)
      return FuncDec(value: functionName, children: [StringVal(value: functionName, children: []), StringVal(value: arguments.joined(separator: ", "), children: []), NoOp(value: "", children: statements)])
    } else if tokenizer.next.type == "RETURN" {
      tokenizer.selectNext()
      return parseBoolExpression(symbolTable: symbolTable, funcTable: funcTable)
    } else if tokenizer.next.type == "EOL" {
      tokenizer.selectNext()
      return NoOp(value: "", children: [])
    } else {
      fatalError("Invalid statement")
    }
    return NoOp(value: "", children: [])
  }

  private func parseBlock(symbolTable: SymbolTable, funcTable: FuncTable) -> Node {
    var statements: [Node] = []
    while tokenizer.next.type != "EOF" {
      let statement = parseStatement(symbolTable: symbolTable, funcTable: funcTable)
      statements.append(statement)
    }
    return NoOp(value: "", children: statements)
  }

  public func run(code: String, symbolTable: SymbolTable, funcTable: FuncTable) -> Node {
    let filteredCode = PrePro.filter(code: code)
    self.tokenizer = Tokenizer(source: filteredCode)
    tokenizer.selectNext() // Position the tokenizer to the first token
    return parseBlock(symbolTable: symbolTable, funcTable: funcTable)
  }
}

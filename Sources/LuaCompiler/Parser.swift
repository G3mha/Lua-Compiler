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
      let name = tokenizer.next.value
      tokenizer.selectNext()
      if tokenizer.next.type == "LPAREN" {
        tokenizer.selectNext()
        var arguments: [Node] = []
        while tokenizer.next.type != "RPAREN" {
          let argument = parseBoolExpression(symbolTable: symbolTable, funcTable: funcTable)
          arguments.append(argument)
          if tokenizer.next.type == "COMMA" {
            tokenizer.selectNext()
          } else if tokenizer.next.type != "RPAREN" {
            fatalError("Missing comma between function arguments")
          }
        }
        tokenizer.selectNext()
        return FuncCall(value: name, children: arguments)
      } else {
        return VarAccess(value: name, children: [])
      }
    } else if tokenizer.next.type == "PLUS" || tokenizer.next.type == "MINUS" || tokenizer.next.type == "NOT" {
      let operatorType = tokenizer.next.type
      tokenizer.selectNext()
      return UnOp(value: operatorType, children: [parseFactor(symbolTable: symbolTable, funcTable: funcTable)])
    } else if tokenizer.next.type == "LPAREN" {
      tokenizer.selectNext()
      let result = parseBoolExpression(symbolTable: symbolTable, funcTable: funcTable)
      if tokenizer.next.type != "RPAREN" {
        fatalError("Missing closing parenthesis")
      }
      tokenizer.selectNext()
      return result
    } else if tokenizer.next.type == "READ" {
      tokenizer.selectNext()
      if tokenizer.next.type != "LPAREN" {
        fatalError("Missing opening parenthesis for read statement")
      }
      tokenizer.selectNext()
      if tokenizer.next.type != "RPAREN" {
        fatalError("Missing closing parenthesis for read statement")
      }
      tokenizer.selectNext()
      return ReadOp(value: "READ", children: [])
    } else {
      fatalError("Invalid factor: (\(tokenizer.next.type), \(tokenizer.next.value))")
    }
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

  private func parseStatement(symbolTable: SymbolTable, funcTable: FuncTable) -> Node {
    if tokenizer.next.type == "EOL" {
      tokenizer.selectNext()
      return NoOp(value: "", children: [])
    } else if tokenizer.next.type == "IDENTIFIER" {
      let name = tokenizer.next.value
      tokenizer.selectNext()
      if tokenizer.next.type == "ASSIGN" {
        tokenizer.selectNext()
        let expression = parseBoolExpression(symbolTable: symbolTable, funcTable: funcTable)
        return VarAssign(value: name, children: [expression])
      } else if tokenizer.next.type == "LPAREN" {
        tokenizer.selectNext()
        var arguments: [Node] = []
        while tokenizer.next.type != "RPAREN" {
          let argument = parseBoolExpression(symbolTable: symbolTable, funcTable: funcTable)
          arguments.append(argument)
          if tokenizer.next.type == "COMMA" {
            tokenizer.selectNext()
          } else if tokenizer.next.type != "RPAREN" {
            fatalError("Missing comma between function arguments")
          }
        }
        tokenizer.selectNext()
        return FuncCall(value: name, children: arguments)
      } else {
        fatalError("Invalid statement")
      }
    } else if tokenizer.next.type == "PRINT" {
      tokenizer.selectNext()
      if tokenizer.next.type != "LPAREN" {
        fatalError("Missing opening parenthesis for print statement")
      }
      tokenizer.selectNext()
      let expression = parseBoolExpression(symbolTable: symbolTable, funcTable: funcTable)
      if tokenizer.next.type != "RPAREN" {
        fatalError("Missing closing parenthesis for print statement")
      }
      tokenizer.selectNext()
      return PrintOp(value: "PRINT", children: [expression])
    } else if tokenizer.next.type == "WHILE" {
      tokenizer.selectNext()
      let condition = parseBoolExpression(symbolTable: symbolTable, funcTable: funcTable)
      if tokenizer.next.type != "DO" {
        fatalError("Missing DO after WHILE condition")
      }
      tokenizer.selectNext()
      if tokenizer.next.type != "EOL" {
        fatalError("Missing EOL after DO")
      }
      tokenizer.selectNext()
      var statements: [Node] = []
      while tokenizer.next.type != "END" {
        let statement = parseStatement(symbolTable: symbolTable, funcTable: funcTable)
        statements.append(statement)
      }
      tokenizer.selectNext()
      if tokenizer.next.type != "EOL" {
        fatalError("Missing EOL after END")
      }
      return WhileOp(value: "WHILE", children: [condition, Statements(value: "", children: statements)])
    } else if tokenizer.next.type == "IF" {
      tokenizer.selectNext()
      let condition = parseBoolExpression(symbolTable: symbolTable, funcTable: funcTable)
      if tokenizer.next.type != "THEN" {
        fatalError("Missing THEN after IF condition")
      }
      tokenizer.selectNext()
      if tokenizer.next.type != "EOL" {
        fatalError("Missing EOL after THEN")
      }
      tokenizer.selectNext()
      var ifStatements: [Node] = []
      while tokenizer.next.type != "END" && tokenizer.next.type != "ELSE" {
        let statement = parseStatement(symbolTable: symbolTable, funcTable: funcTable)
        ifStatements.append(statement)
      }
      var elseStatements: [Node] = []
      if tokenizer.next.type == "ELSE" {
        tokenizer.selectNext()
        while tokenizer.next.type != "END" {
          let statement = parseStatement(symbolTable: symbolTable, funcTable: funcTable)
          elseStatements.append(statement)
        }
      }
      tokenizer.selectNext()
      if tokenizer.next.type != "EOL" {
        fatalError("Missing EOL after END")
      }
      return IfOp(value: "IF", children: [condition, Statements(value: "", children: ifStatements), Statements(value: "", children: elseStatements)])
    } else if tokenizer.next.type == "LOCAL" {
      tokenizer.selectNext()
      if tokenizer.next.type != "IDENTIFIER" {
        fatalError("Invalid variable name in declaration")
      }
      let variableName = tokenizer.next.value
      tokenizer.selectNext()
      if tokenizer.next.type == "ASSIGN" {
        tokenizer.selectNext()
        let expression = parseBoolExpression(symbolTable: symbolTable, funcTable: funcTable)
        return VarAssign(value: variableName, children: [expression])
      } else {
        return VarDec(value: variableName, children: [])
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
      var functionItems: [Node] = []
      while tokenizer.next.type != "RPAREN" {
        if tokenizer.next.type == "IDENTIFIER" {
          functionItems.append(VarDec(value: tokenizer.next.value, children: []))
          tokenizer.selectNext()
          if tokenizer.next.type == "COMMA" {
            tokenizer.selectNext()
          } else if tokenizer.next.type != "RPAREN" {
            fatalError("Missing comma between function arguments")
          }
        } else {
          fatalError("Invalid argument name in function declaration")
        }
      }
      tokenizer.selectNext()
      if tokenizer.next.type != "EOL" {
        fatalError("Missing EOL after function arguments")
      }
      tokenizer.selectNext()
      var statements: [Node] = []
      while tokenizer.next.type != "END" {
        let statement = parseStatement(symbolTable: symbolTable, funcTable: funcTable)
        statements.append(statement)
      }
      functionItems.append(Block(value: "", children: statements))
      if tokenizer.next.type != "END" {
        fatalError("Missing END after function declaration")
      }
      tokenizer.selectNext()
      if tokenizer.next.type != "EOL" {
        fatalError("Missing EOL after END")
      }
      return FuncDec(value: functionName, children: functionItems)
    } else if tokenizer.next.type == "RETURN" {
      tokenizer.selectNext()
      let expression = parseBoolExpression(symbolTable: symbolTable, funcTable: funcTable)
      return ReturnOp(value: "RETURN", children: [expression])
    } else {
      fatalError("Invalid statement")
    }
  }

  private func parseBlock(symbolTable: SymbolTable, funcTable: FuncTable) -> Node {
    var statements: [Node] = []
    while tokenizer.next.type != "EOF" {
      let statement = parseStatement(symbolTable: symbolTable, funcTable: funcTable)
      statements.append(statement)
    }
    return Block(value: "", children: statements)
  }

  public func run(code: String, symbolTable: SymbolTable, funcTable: FuncTable) -> Node {
    let filteredCode = PrePro.filter(code: code)
    self.tokenizer = Tokenizer(source: filteredCode)
    tokenizer.selectNext() // Position the tokenizer to the first token
    return parseBlock(symbolTable: symbolTable, funcTable: funcTable)
  }
}

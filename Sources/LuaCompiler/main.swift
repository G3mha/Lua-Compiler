import Foundation

func main() {
  // Ensure there is at least one command line argument for the file path.
  guard CommandLine.arguments.count > 1 else {
    writeStderrAndExit("Please provide a .lua file path.")
    return // This is not necessary, but it makes the compiler happy.
  }

  let fileContent = readFile(CommandLine.arguments[1])
  let symbolTable = SymbolTable()
  let myParser = Parser()
  let ast = myParser.run(code: fileContent, symbolTable: symbolTable)
  let _ = ast.evaluate(symbolTable: symbolTable)
}

import Foundation


class Compiler {
  enum CompilerError: Error {
      case NoInput
      case NoOperators
      case MissingAtLeast2Numbers
      case MissingAtLeast1Number
      case TwoConsecutiveOperators
      case NegativeResult(result: Int)
  }

  static func run() {
    let inputString = CommandLine.arguments[1...].joined(separator: "")
    do {
      let result = try sumSub(inputWithoutSpaces: inputString)
      print(result)
    } catch CompilerError.NoInput {
      print("ERROR: No input")
    } catch CompilerError.NoOperators {
      print("ERROR: No operators found")
    } catch CompilerError.MissingAtLeast2Numbers {
      print("ERROR: Missing at least 2 numbers")
    } catch CompilerError.MissingAtLeast1Number {
      print("ERROR: Missing at least 1 number")
    } catch CompilerError.TwoConsecutiveOperators {
      print("ERROR: Two consecutive operators")
    } catch CompilerError.NegativeResult(let result) {
      print("ERROR: Negative result: \(result)")
    } catch {
      print("ERROR: An error occurred")
    }
  }
  
  static func sumSub(inputWithoutSpaces: String) throws -> Int {
    if inputWithoutSpaces.isEmpty {
      throw CompilerError.NoInput
    }

    if inputWithoutSpaces.contains("++") || inputWithoutSpaces.contains("--") || inputWithoutSpaces.contains("+-") || inputWithoutSpaces.contains("-+") {
      throw CompilerError.TwoConsecutiveOperators
    }

    let splitBySum = inputWithoutSpaces.components(separatedBy: "+")
    let splitBySub = inputWithoutSpaces.components(separatedBy: "-")
    
    if splitBySum == ["", ""] || splitBySub == ["", ""] {
      throw CompilerError.MissingAtLeast2Numbers
    }

    // if list length is 2 and one of the items is empty
    if (splitBySum.count == 2 || splitBySub.count == 2) && (splitBySum.contains("") || splitBySub.contains("")) {
      throw CompilerError.MissingAtLeast1Number
    }
    if splitBySum.count == 1 && splitBySub.count == 1 {
        throw CompilerError.NoOperators
    }

    var result = 0
    for sum in splitBySum {
      let sub = sum.components(separatedBy: "-")
      if sub.count > 1 {
        for (index, number) in sub.enumerated() {
          if index == 0 {
            result += Int(number) ?? 0
          } else {
            result -= Int(number) ?? 0
          }
        }
      } else {
        result += Int(sum) ?? 0
      }
    }
    if result < 0 {
      throw CompilerError.NegativeResult(result: result)
    }
    return result
  }
}

// Run the compiler
Compiler.run()
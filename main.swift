import Foundation


class Compiler {
  enum CompilerError: Error {
      case NoOperators
      case WhiteSpacesBetweenNumbers
      case TwoConsecutiveOperators
      case NegativeResult(result: Int)
  }

  static func run() {
    let inputString = CommandLine.arguments[1]
    do {
      let result = try sumSub(input: inputString)
      print(result)
    } catch CompilerError.NoOperators {
      print("ERROR: No operators found")
    } catch CompilerError.WhiteSpacesBetweenNumbers {
      print("ERROR: White spaces between numbers")
    } catch CompilerError.TwoConsecutiveOperators {
      print("ERROR: Two consecutive operators")
    } catch CompilerError.NegativeResult(let result) {
      print("ERROR: Negative result: \(result)")
    } catch {
      print("ERROR: An error occurred")
    }
  }
  
  static func sumSub(input: String) throws -> Int {
    if input.contains(" ") {
      throw CompilerError.WhiteSpacesBetweenNumbers
    }
    if input.contains("++") || input.contains("--") || input.contains("+-") || input.contains("-+") {
      throw CompilerError.TwoConsecutiveOperators
    }
    var result = 0
    let splitBySum = input.components(separatedBy: "+")
    if splitBySum.count == 1 {
      let splitBySub = input.components(separatedBy: "-")
      if splitBySub.count == 1 {
        throw CompilerError.NoOperators
      }
    }
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
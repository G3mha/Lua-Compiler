import Foundation

class Compiler {
  static func run() {
    let inputString = CommandLine.arguments[1]
    let result = sumSub(input: inputString)
    print(result)
  }
  
  static func sumSub(input: String) -> Int {
    var result = 0
    let splitBySum = input.components(separatedBy: "+")
    for sum in splitBySum {
      let sub = sum.components(separatedBy: "-")
      if sub.count > 1 {
        let first = Int(sub[0]) ?? 0
        let second = Int(sub[1]) ?? 0
        result += first - second
      } else {
        result += Int(sum) ?? 0
      }
    }
    return result
  }
}

// Run the compiler
Compiler.run()
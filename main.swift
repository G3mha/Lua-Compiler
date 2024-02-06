import Foundation

func calculator(input: String) -> Int {
  // create a variable to store the final result
  var result = 0
  
  // first split by "+"
  let splitBySum = input.components(separatedBy: "+")
  
  // than split each element by "-"
  for sum in splitBySum {
    let sub = sum.components(separatedBy: "-")
    if sub.count > 1 {
      let first = Int(sub[0]) ?? 0
      let second = Int(sub[1]) ?? 0
      // if there is a "-" in the element, it's a sub element
      result += first - second
    } else {
      // if there is no "-" in the element, it's a sum element
      result += Int(sum) ?? 0
    }
  }

  return result
}

let inputString = CommandLine.arguments[1]
let result = calculator(input: inputString)
print(result)

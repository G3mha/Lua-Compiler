import Foundation

class PrePro {
  static public func filter(code: String) -> String {
    let splittedCode = code.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "\t", with: "").split(separator: "\n")
    var processedCode = ""
    for i in 0..<splittedCode.count {
      let line = splittedCode[i]
      if line.contains("--") {
        if line.prefix(2) != "--" {
          processedCode += String(line.split(separator: "--")[0]) + "\n"
        }
      } else {
        processedCode += String(line) + "\n"
      }
    }
    return processedCode
  }
}

import Foundation

func readFile(_ path: String) -> String {
  do {
    let contents = try String(contentsOfFile: path, encoding: .utf8)
    return contents
  } catch {
    fatalError("Failed to read file")
    return "Error"
  }
}

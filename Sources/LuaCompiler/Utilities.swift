import Foundation

func writeStderrAndExit(_ message: String) {
  // function that writes to stderr a received string and exits with error
  fputs("ERROR: \(message)\n", stderr) // write to stderr
  exit(1) // exit with error
}

func readFile(_ path: String) -> String {
  do {
    let contents = try String(contentsOfFile: path, encoding: .utf8)
    return contents
  } catch {
    writeStderrAndExit("Failed to read file")
    return "Error"
  }
}

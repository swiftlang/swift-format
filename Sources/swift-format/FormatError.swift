import Foundation
import SwiftSyntax

struct FormatError: LocalizedError {
  var message: String
  
  var errorDescription: String? { message }
  
  static func readSource(path: String) -> FormatError {
    FormatError(message: "Unable to read source for linting from \(path).")
  }
  
  static func unableToLint(path: String, message: String) -> FormatError {
    FormatError(message: "Unable to lint \(path): \(message).")
  }
  
  static func unableToFormat(path: String, message: String) -> FormatError {
    FormatError(message: "Unable to format \(path): \(message).")
  }
  
  static func invalidSyntax(location: SourceLocation, message: String) -> FormatError {
    FormatError(message: "Unable to format at \(location): \(message).")
  }
  
  static var exitWithDiagnosticErrors: FormatError {
    // The diagnostics engine has already printed errors to stderr.
    FormatError(message: "")
  }
}


import Foundation
import SwiftSyntax

struct FormatError: LocalizedError {
  var message: String
  var errorDescription: String? { message }
  
  static var exitWithDiagnosticErrors: FormatError {
    // The diagnostics engine has already printed errors to stderr.
    FormatError(message: "")
  }
}


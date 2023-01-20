import SwiftSyntax

/// Rewrites the trivia on tokens in the given source file to restore the legacy trivia behavior
/// before https://github.com/apple/swift-syntax/pull/985 was merged.
///
/// Eventually we should get rid of this and update the core formatting code to adjust to the new
/// behavior, but this workaround lets us keep the current implementation without larger changes.
public func restoringLegacyTriviaBehavior(_ sourceFile: SourceFileSyntax) -> SourceFileSyntax {
  return LegacyTriviaBehaviorRewriter().visit(sourceFile)
}

private final class LegacyTriviaBehaviorRewriter: SyntaxRewriter {
  /// Trivia that was extracted from the trailing trivia of a token to be prepended to the leading
  /// trivia of the next token.
  private var pendingLeadingTrivia: Trivia?

  override func visit(_ token: TokenSyntax) -> TokenSyntax {
    var token = token
    if let pendingLeadingTrivia = pendingLeadingTrivia {
      token = token.with(\.leadingTrivia, pendingLeadingTrivia + token.leadingTrivia)
      self.pendingLeadingTrivia = nil
    }
    if token.nextToken != nil,
      let firstIndexToMove = token.trailingTrivia.firstIndex(where: shouldTriviaPieceBeMoved)
    {
      pendingLeadingTrivia = Trivia(pieces: Array(token.trailingTrivia[firstIndexToMove...]))
      token =
        token.with(\.trailingTrivia, Trivia(pieces: Array(token.trailingTrivia[..<firstIndexToMove])))
    }
    return token
  }
}

/// Returns a value indicating whether the given trivia piece should be moved from a token's
/// trailing trivia to the leading trivia of the following token to restore the legacy trivia
/// behavior.
private func shouldTriviaPieceBeMoved(_ piece: TriviaPiece) -> Bool {
  switch piece {
  case .spaces, .tabs, .unexpectedText:
    return false
  default:
    return true
  }
}

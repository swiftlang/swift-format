import SwiftSyntax

/// Enforces a configurable policy for blank lines at the significant syntactic boundaries of a
/// source file.
///
/// The policy is expressed through the `blankLinePolicy` configuration object. Each of its axes
/// covers one kind of boundary and accepts the primitive values `none` (blank lines are
/// forbidden), `exactlyOne` (exactly one blank line is required), and `optional` (the author may
/// choose zero or one), along with a few named expansions of those primitives:
///
///   - `betweenDeclarations: "scopeSeparated"` and `members: "scopeSeparated"` apply
///     `exactlyOne` between scope-like declarations (functions, initializers, computed
///     properties, nested types) and at kind transitions, and `optional` between list-like
///     declarations of the same kind (stored properties, enum cases, typealiases, imports).
///   - `switchCases: "auto"` applies `exactlyOne` between adjacent cases when either case is
///     multiline and `none` between adjacent single-line cases.
///   - `guardPrologue: "separated"` keeps consecutive leading guard statements tight and applies
///     `exactlyOne` after the final leading guard statement.
///
/// Blank lines inside multi-line string literals and comments are content and are never
/// modified. The `scopeEdges` axis generalizes the `NoEmptyLinesOpeningClosingBraces` rule; it
/// defaults to `optional` so that enabling both does not produce duplicate findings.
///
/// Lint: Blank lines that violate the configured policy yield a lint error.
///
/// Format: Blank lines that violate the configured policy are removed, and required blank lines
/// are inserted.
@_spi(Rules)
public final class BlankLinePolicy: SyntaxFormatRule {
  public override class var isOptIn: Bool { true }

  private var policy: BlankLinePolicyConfiguration {
    context.configuration.blankLinePolicy
  }

  public override func visit(_ node: SourceFileSyntax) -> SourceFileSyntax {
    Rewriter(rule: self).run(node)
  }
}

extension BlankLinePolicy {
  /// The passes the rule runs over the file.
  fileprivate enum Phase {
    /// Walks the original tree unchanged, emitting findings whose locations are computed
    /// against the unmodified source, and recording the planned leading-trivia edits.
    case collect
    /// Walks the tree again, applying the recorded edits.
    case apply
  }

  /// A change made to the blank lines at a boundary, for diagnostics.
  fileprivate enum Change {
    case inserted
    case removed(Int)
  }

  /// Performs the policy's two passes over a file.
  ///
  /// Entering at the root of the file is what drives this rewriter; it is never dispatched
  /// per-node by a pipeline, so it needs no guards against reentrant visits.
  fileprivate final class Rewriter: SyntaxRewriter {
    private let rule: BlankLinePolicy

    /// The pass that the rewriter is currently performing.
    private var phase: Phase = .collect

    /// The leading-trivia edits recorded during the collect pass, keyed by the depth-first index
    /// of the node whose leading trivia must be replaced.
    ///
    /// A full `SyntaxIdentifier` cannot be used as the key: edits made during the apply pass
    /// rebuild the tree, which changes the root identifier that it is based on. The depth-first
    /// index is stable, though, because the rule's edits only replace tokens (trivia) and never
    /// insert or remove nodes — the scenario in which SwiftSyntax guarantees that indices can be
    /// shared between the original and mutated trees.
    private var pendingLeadingTrivia: [SyntaxIdentifier.SyntaxIndexInTree: Trivia] = [:]

    private var context: Context {
      rule.context
    }

    private var policy: BlankLinePolicyConfiguration {
      rule.policy
    }

    init(rule: BlankLinePolicy) {
      self.rule = rule
    }

    func run(_ node: SourceFileSyntax) -> SourceFileSyntax {
      phase = .collect
      pendingLeadingTrivia.removeAll()
      _ = visit(node)
      phase = .apply
      return visit(node)
    }

    // MARK: Top-level declarations

    override func visit(_ node: SourceFileSyntax) -> SourceFileSyntax {
      stageBoundaries(node.statements, boundary: "between declarations", targetFor: topLevelTarget)
      return super.visit(node)
    }

    // MARK: Brace scopes

    override func visit(_ node: CodeBlockSyntax) -> CodeBlockSyntax {
      var adjusted = node
      if policy.scopeEdges == .none {
        adjusted = trimmingClosingBrace(adjusted, brace: \CodeBlockSyntax.rightBrace)
        stageFirstBoundaryEdit(adjusted.statements)
      }
      stageGuardPrologueEdits(adjusted.statements)
      return super.visit(adjusted)
    }

    override func visit(_ node: MemberBlockSyntax) -> MemberBlockSyntax {
      var adjusted = node
      if policy.scopeEdges == .none {
        adjusted = trimmingClosingBrace(adjusted, brace: \MemberBlockSyntax.rightBrace)
        stageFirstBoundaryEdit(adjusted.members)
      }
      stageBoundaries(adjusted.members, boundary: "between members", targetFor: memberTarget)
      return super.visit(adjusted)
    }

    override func visit(_ node: ClosureExprSyntax) -> ExprSyntax {
      var adjusted = node
      if policy.scopeEdges == .none {
        adjusted = trimmingClosingBrace(adjusted, brace: \ClosureExprSyntax.rightBrace)
        stageFirstBoundaryEdit(adjusted.statements)
      }
      stageGuardPrologueEdits(adjusted.statements)
      return super.visit(adjusted)
    }

    override func visit(_ node: AccessorBlockSyntax) -> AccessorBlockSyntax {
      var adjusted = node
      if policy.scopeEdges == .none {
        adjusted = trimmingClosingBrace(adjusted, brace: \AccessorBlockSyntax.rightBrace)
        switch adjusted.accessors {
        case .accessors(let accessors):
          stageFirstBoundaryEdit(accessors)
        case .getter(let statements):
          // A computed property without an explicit getter still has a brace scope.
          stageFirstBoundaryEdit(statements)
        }
      }
      return super.visit(adjusted)
    }

    override func visit(_ node: PrecedenceGroupDeclSyntax) -> DeclSyntax {
      var adjusted = node
      if policy.scopeEdges == .none {
        adjusted = trimmingClosingBrace(adjusted, brace: \PrecedenceGroupDeclSyntax.rightBrace)
        // The attribute list's elements have no dedicated item visits, so the staged edit for
        // its first element is applied here; precedence groups are rare and tiny.
        stageFirstBoundaryEdit(adjusted.groupAttributes, boundary: "after '{'")
        if phase == .apply, var first = adjusted.groupAttributes.first,
          let trivia = pendingLeadingTrivia[first.id.indexInTree]
        {
          first.leadingTrivia = trivia
          adjusted.groupAttributes[adjusted.groupAttributes.startIndex] = first
        }
      }
      return super.visit(adjusted)
    }

    // MARK: Switch statements

    override func visit(_ node: SwitchExprSyntax) -> ExprSyntax {
      var adjusted = node
      if policy.scopeEdges == .none {
        adjusted = trimmingClosingBrace(adjusted, brace: \SwitchExprSyntax.rightBrace)
        stageFirstBoundaryEdit(adjusted.cases)
      }
      stageBoundaries(adjusted.cases, boundary: "between switch cases", targetFor: switchCaseTarget)
      return super.visit(adjusted)
    }

    override func visit(_ node: SwitchCaseSyntax) -> SwitchCaseSyntax {
      var adjusted = applyingPendingTrivia(node)
      if policy.afterCaseLabel == .none {
        stageFirstBoundaryEdit(adjusted.statements, boundary: "after case label")
      }
      return super.visit(adjusted)
    }

    // MARK: Conditional compilation

    override func visit(_ node: IfConfigClauseSyntax) -> IfConfigClauseSyntax {
      var adjusted = node
      switch adjusted.elements {
      case .none:
        break
      case .statements(let statements):
        if policy.conditionalCompilationEdges == .none {
          stageFirstBoundaryEdit(
            statements,
            boundary: "after a conditional compilation directive"
          )
        }
        if Self.isTopLevelClause(node) {
          // At the top level of a file the payload holds declarations, even though they are
          // wrapped in code block items.
          stageBoundaries(
            statements,
            boundary: "between declarations",
            targetFor: topLevelTarget
          )
        } else {
          stageGuardPrologueEdits(statements)
        }
      case .switchCases(let switchCases):
        if policy.conditionalCompilationEdges == .none {
          stageFirstBoundaryEdit(
            switchCases,
            boundary: "after a conditional compilation directive"
          )
        }
        stageBoundaries(
          switchCases,
          boundary: "between switch cases",
          targetFor: switchCaseTarget
        )
      case .decls(let members):
        // Declaration payloads occur for `#if` blocks inside type bodies, so their boundaries
        // are governed by the `members` policy.
        if policy.conditionalCompilationEdges == .none {
          stageFirstBoundaryEdit(
            members,
            boundary: "after a conditional compilation directive"
          )
        }
        stageBoundaries(members, boundary: "between members", targetFor: memberTarget)
      case .attributes(let attributes):
        if policy.conditionalCompilationEdges == .none {
          stageFirstBoundaryEdit(
            attributes,
            boundary: "after a conditional compilation directive"
          )
        }
      case .postfixExpression(let original):
        var expression = original
        if policy.conditionalCompilationEdges == .none {
          let key = original.id.indexInTree
          switch phase {
          case .collect:
            if context.shouldFormat(BlankLinePolicy.self, node: Syntax(original)) {
              let (trivia, change) = Self.rewritingFirstNewlineRun(
                in: original.leadingTrivia,
                target: 1
              )
              if let change {
                diagnoseChange(
                  change,
                  on: original,
                  boundary: "after a conditional compilation directive",
                  anchor: .leadingTrivia(0)
                )
                pendingLeadingTrivia[key] = trivia
              }
            }
          case .apply:
            if let trivia = pendingLeadingTrivia[key] {
              expression.leadingTrivia = trivia
              adjusted.elements = .postfixExpression(expression)
            }
          }
        }
      }
      return super.visit(adjusted)
    }

    override func visit(_ node: IfConfigDeclSyntax) -> DeclSyntax {
      var adjusted = node
      if policy.conditionalCompilationEdges == .none {
        let poundEndif = node.poundEndif
        let key = poundEndif.id.indexInTree
        switch phase {
        case .collect:
          if context.shouldFormat(BlankLinePolicy.self, node: Syntax(poundEndif)) {
            let (trivia, change) = Self.rewritingFirstNewlineRun(
              in: poundEndif.leadingTrivia,
              target: 1
            )
            if let change {
              diagnoseChange(change, on: poundEndif, boundary: "before '#endif'", anchor: .start)
              pendingLeadingTrivia[key] = trivia
            }
          }
        case .apply:
          if let trivia = pendingLeadingTrivia[key] {
            adjusted.poundEndif = poundEndif.with(\.leadingTrivia, trivia)
          }
        }
      }
      return super.visit(adjusted)
    }

    // MARK: Expressions

    override func visit(_ node: LabeledExprListSyntax) -> LabeledExprListSyntax {
      if policy.expressions == .none {
        stageBoundaries(node, boundary: "between arguments", marksEnabled: false) { _, _ in 1 }
      }
      return super.visit(node)
    }

    override func visit(_ node: ArrayElementListSyntax) -> ArrayElementListSyntax {
      if policy.expressions == .none {
        stageBoundaries(node, boundary: "between collection elements", marksEnabled: false) { _, _ in 1 }
      }
      return super.visit(node)
    }

    override func visit(_ node: DictionaryElementListSyntax) -> DictionaryElementListSyntax {
      if policy.expressions == .none {
        stageBoundaries(node, boundary: "between collection elements", marksEnabled: false) { _, _ in 1 }
      }
      return super.visit(node)
    }

    // MARK: Collection items (apply pass)

    // During the apply pass these visits perform the edits staged by the boundary helpers,
    // letting the rewriter batch each parent collection's rebuild.
    override func visit(_ node: CodeBlockItemSyntax) -> CodeBlockItemSyntax {
      super.visit(applyingPendingTrivia(node))
    }

    override func visit(_ node: MemberBlockItemSyntax) -> MemberBlockItemSyntax {
      super.visit(applyingPendingTrivia(node))
    }

    override func visit(_ node: LabeledExprSyntax) -> LabeledExprSyntax {
      super.visit(applyingPendingTrivia(node))
    }

    override func visit(_ node: ArrayElementSyntax) -> ArrayElementSyntax {
      super.visit(applyingPendingTrivia(node))
    }

    override func visit(_ node: DictionaryElementSyntax) -> DictionaryElementSyntax {
      super.visit(applyingPendingTrivia(node))
    }

    override func visit(_ node: AttributeSyntax) -> AttributeSyntax {
      super.visit(applyingPendingTrivia(node))
    }

    override func visit(_ node: AccessorDeclSyntax) -> DeclSyntax {
      super.visit(applyingPendingTrivia(node))
    }

    // MARK: Tokens: attribute gaps and control flow keywords

    override func visit(_ token: TokenSyntax) -> TokenSyntax {
      var result = token

      // The gap policies only ever remove blank lines, which requires a newline in the leading
      // trivia; checking for one first avoids walking to the previous token for every token in
      // the file.
      if policy.attributes == .none,
        result.leadingTrivia.contains(where: { $0.isAnyNewline }),
        let previous = result.previousToken(viewMode: .sourceAccurate),
        Self.isLastTokenOfAttribute(previous)
      {
        result = trimmingTokenGap(result, boundary: "after an attribute")
      }

      if policy.beforeElse == .none {
        switch result.tokenKind {
        case .keyword(.else), .keyword(.catch):
          result = trimmingTokenGap(
            result,
            boundary: result.tokenKind == .keyword(.else) ? "before 'else'" : "before 'catch'"
          )
        default:
          break
        }
      }

      return result
    }

    // MARK: Guard prologue

    private func stageGuardPrologueEdits(_ statements: CodeBlockItemListSyntax) {
      guard policy.guardPrologue == .separated else { return }
      let items = Array(statements)
      guard items.count > 1 else { return }

      var guardCount = 0
      while guardCount < items.count, items[guardCount].item.is(GuardStmtSyntax.self) {
        guardCount += 1
      }
      guard guardCount > 0 else { return }

      let indices = Array(statements.indices)
      if guardCount < items.count {
        stageBoundaryEdit(
          statements,
          at: indices[guardCount],
          boundary: "after guard statements",
          target: 2
        )
      }
      if guardCount > 1 {
        for i in stride(from: guardCount - 1, through: 1, by: -1) {
          stageBoundaryEdit(
            statements,
            at: indices[i],
            boundary: "between guard statements",
            target: 1
          )
        }
      }
    }

    // MARK: Shared machinery

    /// Stages the edits for the blank lines before each item (except the first) of a syntax
    /// collection.
    ///
    /// `targetFor` receives the previous and current items and returns the number of newlines
    /// that must separate the previous item from the current one, or nil to leave the boundary
    /// alone. If `marksEnabled` is true and the current item's leading trivia contains a
    /// `// MARK:` comment, the `marks` policies govern the boundaries around the comment instead
    /// (MARK policies are meaningless inside expressions, hence the parameter).
    private func stageBoundaries<C: SyntaxCollection>(
      _ collection: C,
      boundary: String,
      marksEnabled: Bool = true,
      targetFor: (C.Element, C.Element) -> Int?
    ) {
      guard phase == .collect else { return }
      let elements = Array(collection)
      let indices = Array(collection.indices)

      for i in 0..<elements.count {
        let current = elements[i]

        if marksEnabled, Self.markCommentIndex(in: current.leadingTrivia) != nil {
          // A `// MARK:` comment governs its own boundaries instead of the axis's policy; both
          // of its edits compose into a single staged trivia for the item, on top of anything
          // another axis has already staged for it. On the first item the scope-edge policy owns
          // the boundary before the comment, so only `after` applies there.
          let key = current.id.indexInTree
          guard context.shouldFormat(BlankLinePolicy.self, node: Syntax(current)) else {
            continue
          }
          var trivia = pendingLeadingTrivia[key] ?? current.leadingTrivia
          var changed = false

          if i > 0, let target = policy.marks.before.targetNewlines {
            let (newTrivia, change) = Self.rewritingFirstNewlineRun(in: trivia, target: target)
            if let change {
              diagnoseChange(
                change,
                on: current,
                boundary: "before 'MARK:'",
                anchor: .leadingTrivia(0)
              )
              trivia = newTrivia
              changed = true
            }
          }
          if let target = policy.marks.after.targetNewlines,
            let commentIndex = Self.markCommentIndex(in: trivia)
          {
            let (newTrivia, change) = Self.rewritingFirstNewlineRun(
              in: trivia,
              atOrAfter: commentIndex + 1,
              target: target
            )
            if let change {
              diagnoseChange(change, on: current, boundary: "after 'MARK:'", anchor: .start)
              trivia = newTrivia
              changed = true
            }
          }
          if changed {
            pendingLeadingTrivia[key] = trivia
          }
        } else if i > 0, let target = targetFor(elements[i - 1], current) {
          stageBoundaryEdit(collection, at: indices[i], boundary: boundary, target: target)
        }
      }
    }

    /// Stages the edit that gives the item at `index` the given newline target.
    ///
    /// The edit is recorded, keyed by the item's depth-first index, and a finding is emitted
    /// against the unmodified source; recorded edits are performed during the apply pass by the
    /// items' own visits, so that the rewriter rebuilds each parent collection at most once. The
    /// rule mask is only consulted here: re-checking it during the apply pass would compare
    /// positions in the already-mutated tree against the mask's original-source ranges, silently
    /// dropping edits near ignored regions.
    private func stageBoundaryEdit<C: SyntaxCollection>(
      _ collection: C,
      at index: C.Index,
      boundary: String,
      target: Int
    ) {
      guard phase == .collect else { return }
      let item = collection[index]
      let key = item.id.indexInTree
      guard context.shouldFormat(BlankLinePolicy.self, node: Syntax(item)) else {
        return
      }
      let base = pendingLeadingTrivia[key] ?? item.leadingTrivia
      let (trivia, change) = Self.rewritingFirstNewlineRun(in: base, target: target)
      guard let change else { return }
      diagnoseChange(change, on: item, boundary: boundary, anchor: .leadingTrivia(0))
      pendingLeadingTrivia[key] = trivia
    }

    /// Returns the node with its staged leading trivia applied, for use by the item visits of the
    /// apply pass.
    private func applyingPendingTrivia<Node: SyntaxProtocol>(_ node: Node) -> Node {
      guard phase == .apply, let trivia = pendingLeadingTrivia[node.id.indexInTree] else {
        return node
      }
      var adjusted = node
      adjusted.leadingTrivia = trivia
      return adjusted
    }

    /// Stages the removal of any blank line between the start of a scope and its first item.
    private func stageFirstBoundaryEdit<C: SyntaxCollection>(
      _ collection: C,
      boundary: String = "after '{'"
    ) {
      guard collection.first != nil else { return }
      stageBoundaryEdit(collection, at: collection.startIndex, boundary: boundary, target: 1)
    }

    /// Removes any blank line between the last item of a scope and its closing brace.
    private func trimmingClosingBrace<Node: SyntaxProtocol>(
      _ node: Node,
      brace: WritableKeyPath<Node, TokenSyntax>
    ) -> Node {
      guard policy.scopeEdges == .none else { return node }
      let token = node[keyPath: brace]
      let key = token.id.indexInTree
      switch phase {
      case .collect:
        guard context.shouldFormat(BlankLinePolicy.self, node: Syntax(token)) else {
          return node
        }
        let (trivia, change) = Self.rewritingLastNewlineRun(in: token.leadingTrivia, target: 1)
        guard let change else { return node }
        diagnoseChange(change, on: token, boundary: "before '}'", anchor: .start)
        pendingLeadingTrivia[key] = trivia
        return node
      case .apply:
        guard let trivia = pendingLeadingTrivia[key] else { return node }
        var result = node
        result[keyPath: brace] = token.with(\.leadingTrivia, trivia)
        return result
      }
    }

    /// Removes any blank lines in the leading trivia of a token (a gap boundary).
    private func trimmingTokenGap(_ token: TokenSyntax, boundary: String) -> TokenSyntax {
      let key = token.id.indexInTree
      switch phase {
      case .collect:
        guard context.shouldFormat(BlankLinePolicy.self, node: Syntax(token)) else {
          return token
        }
        let (trivia, change) = Self.rewritingFirstNewlineRun(in: token.leadingTrivia, target: 1)
        guard let change else { return token }
        diagnoseChange(change, on: token, boundary: boundary, anchor: .start)
        pendingLeadingTrivia[key] = trivia
        return token
      case .apply:
        guard let trivia = pendingLeadingTrivia[key] else { return token }
        return token.with(\.leadingTrivia, trivia)
      }
    }

    /// Returns whether the declaration is "scope-like": it introduces a brace body or otherwise
    /// behaves like a function (computed properties, subscripts). List-like members (stored
    /// properties, enum cases, typealiases, bodyless protocol requirements) group tightly.
    private func isScopeLike(_ decl: DeclSyntax) -> Bool {
      if decl.is(ClassDeclSyntax.self)
        || decl.is(StructDeclSyntax.self)
        || decl.is(EnumDeclSyntax.self)
        || decl.is(ProtocolDeclSyntax.self)
        || decl.is(ActorDeclSyntax.self)
        || decl.is(ExtensionDeclSyntax.self)
      {
        return true
      }
      if let function = decl.as(FunctionDeclSyntax.self) {
        return function.body != nil
      }
      if let initializer = decl.as(InitializerDeclSyntax.self) {
        return initializer.body != nil
      }
      if decl.is(DeinitializerDeclSyntax.self) {
        return true
      }
      if let subscriptDecl = decl.as(SubscriptDeclSyntax.self) {
        return subscriptDecl.accessorBlock != nil
      }
      if let variable = decl.as(VariableDeclSyntax.self) {
        return variable.bindings.contains { $0.accessorBlock != nil }
      }
      return false
    }

    /// The boundary target between two top-level (or top-level `#if`-region) items under the
    /// `betweenDeclarations` policy.
    private func topLevelTarget(
      _ previous: CodeBlockItemSyntax,
      _ current: CodeBlockItemSyntax
    ) -> Int? {
      declarationTarget(Syntax(previous.item), Syntax(current.item))
    }

    /// The shared core of `betweenDeclarations`: scope-like declarations and kind transitions
    /// are separated by exactly one blank line; the boundary between list-like declarations of
    /// the same kind (for example consecutive imports) and around top-level statements (script
    /// code) is left to the author.
    private func declarationTarget(_ previousItem: Syntax, _ currentItem: Syntax) -> Int? {
      switch policy.betweenDeclarations {
      case .scopeSeparated:
        switch (declaration(inside: previousItem), declaration(inside: currentItem)) {
        case (let previousDecl?, let currentDecl?):
          if isScopeLike(previousDecl) || isScopeLike(currentDecl) {
            return 2
          }
          return previousDecl.kind != currentDecl.kind ? 2 : nil
        default:
          // Items that are not declarations (script code) group with everything; the axis
          // governs declarations.
          return nil
        }
      case .none:
        return 1
      case .exactlyOne:
        return 2
      case .optional:
        return nil
      }
    }

    /// The boundary target between two members under the `members` policy: scope-like members
    /// and kind transitions are separated by exactly one blank line; the boundary between
    /// list-like members of the same kind is left to the author.
    private func memberTarget(
      _ previous: MemberBlockItemSyntax,
      _ current: MemberBlockItemSyntax
    ) -> Int? {
      switch policy.members {
      case .scopeSeparated:
        if isScopeLike(previous.decl) || isScopeLike(current.decl) {
          return 2
        }
        return previous.decl.kind != current.decl.kind ? 2 : nil
      case .none:
        return 1
      case .exactlyOne:
        return 2
      case .optional:
        return nil
      }
    }

    /// The boundary target between two adjacent switch cases.
    private func switchCaseTarget(
      _ previous: SwitchCaseListSyntax.Element,
      _ current: SwitchCaseListSyntax.Element
    ) -> Int? {
      switch policy.switchCases {
      case .auto:
        return (isMultilineCase(previous) || isMultilineCase(current)) ? 2 : 1
      case .none:
        return 1
      case .exactlyOne:
        return 2
      case .optional:
        return nil
      }
    }

    /// Returns the declaration carried by a top-level item, or nil if the item is a statement
    /// (script code).
    private func declaration(inside item: Syntax) -> DeclSyntax? {
      var inner = item
      if let codeBlockItem = item.as(CodeBlockItemSyntax.self) {
        inner = Syntax(codeBlockItem.item)
      }
      return inner.as(DeclSyntax.self)
    }

    /// Returns whether the given clause's conditional compilation block sits at the top level of
    /// the file, so that its payload declarations are governed by `betweenDeclarations` rather
    /// than being treated as ordinary statements.
    private static func isTopLevelClause(_ node: IfConfigClauseSyntax) -> Bool {
      // Walk up through the clause list to the enclosing `#if` declaration, then keep walking to
      // determine whether it sits at the top level of the file.
      var ancestor: Syntax? = Syntax(node).parent
      var sawIfConfigDecl = false
      while let current = ancestor {
        if current.is(IfConfigDeclSyntax.self) {
          sawIfConfigDecl = true
        } else if sawIfConfigDecl {
          switch current.kind {
          case .sourceFile:
            return true
          case .codeBlock, .memberBlock, .closureExpr, .accessorBlock:
            return false
          default:
            break
          }
        }
        ancestor = current.parent
      }
      return false
    }

    private func isMultilineCase(_ element: SwitchCaseListSyntax.Element) -> Bool {
      if case .switchCase(let switchCase) = element {
        return switchCase.trimmedDescription.contains("\n")
      }
      return true
    }

    /// Returns whether the token is the last token of an attribute, so that the gap following it
    /// is governed by the `attributes` policy.
    private static func isLastTokenOfAttribute(_ token: TokenSyntax) -> Bool {
      var ancestor: Syntax? = Syntax(token)
      // Attribute arguments are shallowly nested; the small bound keeps this walk cheap for the
      // common case where the previous token is not part of an attribute at all.
      for _ in 0..<6 {
        guard let parent = ancestor?.parent else { return false }
        if parent.is(AttributeSyntax.self) {
          return parent.lastToken(viewMode: .sourceAccurate) == token
        }
        ancestor = parent
      }
      return false
    }

    /// Returns the index of the first `// MARK:` comment in the trivia, if any.
    private static func markCommentIndex(in trivia: Trivia) -> Int? {
      for (index, piece) in trivia.pieces.enumerated() {
        guard case .lineComment(let text) = piece else { continue }
        let body = text.dropFirst(2).drop(while: { $0 == " " || $0 == "\t" })
        if body.hasPrefix("MARK:") || body.hasPrefix("- MARK:") {
          return index
        }
      }
      return nil
    }

    private struct NewlineRun {
      let index: Int
      let pieceCount: Int
      let newlines: Int
    }

    /// Rewrites the first newline run at or after the boundary so it contains exactly `target`
    /// newlines, and returns the resulting trivia and a description of the change.
    ///
    /// A newline run of *n* newlines corresponds to *n - 1* blank lines, so a target of 1 removes
    /// any blank lines and a target of 2 leaves exactly one. When the trivia contains no newline
    /// run at all (the item continues the previous line), only a target of 2 or more inserts one.
    private static func rewritingFirstNewlineRun(
      in trivia: Trivia,
      atOrAfter start: Int = 0,
      target: Int
    ) -> (trivia: Trivia, change: Change?) {
      var pieces = Array(trivia)
      guard let run = newlineRun(in: pieces, atOrAfter: start) else {
        guard target > 1 else { return (trivia, nil) }
        pieces.insert(.newlines(target), at: min(start, pieces.count))
        return (Trivia(pieces: pieces), .inserted)
      }
      guard run.newlines != target else { return (trivia, nil) }
      pieces.replaceSubrange(run.index..<(run.index + run.pieceCount), with: [.newlines(target)])
      let change: Change = run.newlines < target ? .inserted : .removed(run.newlines - target)
      return (Trivia(pieces: pieces), change)
    }

    /// Rewrites the last newline run in the trivia so it contains exactly `target` newlines.
    private static func rewritingLastNewlineRun(
      in trivia: Trivia,
      target: Int
    ) -> (trivia: Trivia, change: Change?) {
      var pieces = Array(trivia)
      guard let run = lastNewlineRun(in: pieces), run.newlines != target else {
        return (trivia, nil)
      }
      pieces.replaceSubrange(run.index..<(run.index + run.pieceCount), with: [.newlines(target)])
      let change: Change = run.newlines < target ? .inserted : .removed(run.newlines - target)
      return (Trivia(pieces: pieces), change)
    }

    /// Finds the first run of newlines at or after `start`. A blank line that contains spaces or
    /// tabs is part of the run, so that rewriting the run removes those lines entirely instead of
    /// leaving whitespace-only lines behind.
    private static func newlineRun(in pieces: [TriviaPiece], atOrAfter start: Int) -> NewlineRun? {
      var index = start
      while index < pieces.count, !pieces[index].isAnyNewline {
        index += 1
      }
      guard index < pieces.count else { return nil }

      var end = index
      var newlines = 0
      while end < pieces.count {
        if pieces[end].isAnyNewline {
          newlines += pieces[end].newlineCount
          end += 1
        } else if pieces[end].isSpaceOrTab,
          end + 1 < pieces.count,
          pieces[end + 1].isAnyNewline
        {
          // Whitespace that occupies a line of its own belongs to the blank-line run.
          end += 1
        } else {
          break
        }
      }
      return NewlineRun(index: index, pieceCount: end - index, newlines: newlines)
    }

    /// Finds the last run of newlines, absorbing whitespace-only lines as in `newlineRun`.
    private static func lastNewlineRun(in pieces: [TriviaPiece]) -> NewlineRun? {
      guard let last = pieces.lastIndex(where: { $0.isAnyNewline }) else { return nil }
      var first = last
      while first >= 2, pieces[first - 1].isSpaceOrTab, pieces[first - 2].isAnyNewline {
        first -= 2
      }
      while first > 0, pieces[first - 1].isAnyNewline {
        first -= 1
      }
      let newlines = pieces[first...last].reduce(0) { $0 + $1.newlineCount }
      return NewlineRun(index: first, pieceCount: last - first + 1, newlines: newlines)
    }

    private func diagnoseChange<SyntaxType: SyntaxProtocol>(
      _ change: Change,
      on node: SyntaxType?,
      boundary: String,
      anchor: FindingAnchor
    ) {
      // An anchor inside the leading trivia is meaningless when there is none (an item that
      // continues the previous line, such as a statement after a semicolon); anchor on the node's
      // content instead of trapping.
      let anchor: FindingAnchor = node?.leadingTrivia.isEmpty == true ? .start : anchor
      switch change {
      case .inserted:
        rule.diagnose(.insertBlankLine(boundary), on: node, anchor: anchor)
      case .removed(let count):
        rule.diagnose(.removeBlankLines(count, at: boundary), on: node, anchor: anchor)
      }
    }
  }
}

extension BlankLinePolicyValue {
  /// The number of newlines that must separate the previous content from a boundary item, or nil
  /// when the formatter should leave the boundary alone.
  fileprivate var targetNewlines: Int? {
    switch self {
    case .none: 1
    case .exactlyOne: 2
    case .optional: nil
    }
  }
}

extension TriviaPiece {
  fileprivate var isAnyNewline: Bool {
    switch self {
    case .newlines, .carriageReturns, .carriageReturnLineFeeds, .formfeeds: true
    default: false
    }
  }

  fileprivate var newlineCount: Int {
    switch self {
    case .newlines(let count): count
    case .carriageReturns(let count), .carriageReturnLineFeeds(let count), .formfeeds(let count):
      count
    default: 0
    }
  }
}

extension Finding.Message {
  fileprivate static func removeBlankLines(_ count: Int, at boundary: String) -> Finding.Message {
    "remove \(count > 1 ? "\(count) blank lines" : "1 blank line") \(boundary)"
  }

  fileprivate static func insertBlankLine(_ boundary: String) -> Finding.Message {
    "insert a blank line \(boundary)"
  }
}

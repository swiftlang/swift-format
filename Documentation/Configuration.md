# `swift-format` Configuration

`swift-format` allows users to configure a subset of its behavior, both when
used as a command line tool or as an API.

## Command Line Configuration

A `swift-format` configuration file is a JSON file with the following
top-level keys and values:

*   `version` _(number)_: The version of the configuration file. For now, this
    should always be `1`.

*   `lineLength` _(number)_: The maximum allowed length of a line, in
    characters.

*   `indentation` _(object)_: The kind and amount of whitespace that should be
    added when indenting one level. The object value of this property should
    have **exactly one of the following properties:**

    *   `spaces` _(number)_: One level of indentation is the given number of
        spaces.
    *   `tabs` _(number)_: One level of indentation is the given number of
        tabs.

*   `tabWidth` _(number)_: The number of spaces that should be considered
    equivalent to one tab character. This is used during line length
    calculations when tabs are used for indentation.

*   `maximumBlankLines` _(number)_: The maximum number of consecutive blank
    lines that are allowed to be present in a source file. Any number larger
    than this will be collapsed down to the maximum.

*   `respectsExistingLineBreaks` _(boolean)_: Indicates whether or not existing
    line breaks in the source code should be honored (if they are valid
    according to the style guidelines being enforced). If this settings is
    `false`, then the formatter will be more "opinionated" by only inserting
    line breaks where absolutely necessary and removing any others, effectively
    canonicalizing the output.

*   `lineBreakBeforeControlFlowKeywords` _(boolean)_: Determines the
    line-breaking behavior for control flow keywords that follow a closing
    brace, like `else` and `catch`. If true, a line break will be added before
    the keyword, forcing it onto its own line. If false (the default), the
    keyword will be placed after the closing brace (separated by a space).

*   `lineBreakBeforeEachArgument` _(boolean)_: Determines the line-breaking
    behavior for generic arguments and function arguments when a declaration is
    wrapped onto multiple lines. If true, a line break will be added before each
    argument, forcing the entire argument list to be laid out vertically.
    If false (the default), arguments will be laid out horizontally first, with
    line breaks only being fired when the line length would be exceeded.
    
*   `lineBreakBeforeEachGenericRequirement` _(boolean)_:  Determines the 
    line-breaking behavior for generic requirements when the requirements list 
    is wrapped onto multiple lines. If true, a line break will be added before each
    requirement, forcing the entire requirements list to be laid out vertically. If false
    (the default), requirements will be laid out horizontally first, with line breaks 
    only being fired when the line length would be exceeded.

*   `prioritizeKeepingFunctionOutputTogether` _(boolean)_: Determines if 
    function-like declaration outputs should be prioritized to be together with the
    function signature right (closing) parenthesis. If false (the default), function 
    output (i.e. throws, return type) is not prioritized to be together with the 
    signature's right parenthesis, and when the line length would be exceeded,
    a line break will be fired after the function signature first, indenting the 
    declaration output one additional level. If true, A line break will be fired 
    further up in the function's declaration (e.g. generic parameters, 
    parameters) before breaking on the function's output.  

*   `indentConditionalCompilationBlocks` _(boolean)_: Determines if
    conditional compilation blocks are indented. If this setting is `false` the body
    of `#if`, `#elseif`, and `#else` is not indented. Defaults to `true`.

*  `lineBreakAroundMultilineExpressionChainComponents` _(boolean)_:  Determines whether
   line breaks should be forced before and after multiline components of dot-chained
   expressions, such as function calls and subscripts chained together through member
   access (i.e. "." expressions). When any component is multiline and this option is
   true, a line break is forced before the "." of the component and after the component's
   closing delimiter (i.e. right paren, right bracket, right brace, etc.).
   
*  `rules` _(object)_:  Additional rules:

    *   `AllPublicDeclarationsHaveDocumentation` _(boolean)_: All public or open 
        declarations must have a top-level documentation comment. Lint: If a public 
        declaration is missing a documentation comment, a lint error is raised.
    *   `AlwaysUseLowerCamelCase` _(boolean)_: All values should be written in lower 
        camel-case (`lowerCamelCase`). Underscores (except at the beginning of an 
        identifier) are disallowed. Lint: If an identifier contains underscores or begins 
        with a capital letter, a lint error is raised.
    *   `AmbiguousTrailingClosureOverload` _(boolean)_: Overloads with only a closure 
        argument should not be disambiguated by parameter labels. Lint: If two overloaded 
        functions with one closure parameter appear in the same scope, a lint error is 
        raised.
    *   `BeginDocumentationCommentWithOneLineSummary` _(boolean)_: All documentation 
        comments must begin with a one-line summary of the declaration. Lint: If a comment 
        does not begin with a single-line summary, a lint error is raised.
    *   `DoNotUseSemicolons` _(boolean)_: Semicolons should not be present in Swift code. 
        Lint: If a semicolon appears anywhere, a lint error is raised. Format: All  
        semicolons will be replaced with line breaks.
    *   `DontRepeatTypeInStaticProperties` _(boolean)_: Static properties of a type that 
        return that type should not include a reference to their type. "Reference to their 
        type" means that the property name includes part, or all, of the type. If the type 
        contains a namespace (i.e. `UIColor`) the namespace is ignored; `public class var 
        redColor: UIColor` would trigger this rule. Lint: Static properties of a type that 
        return that type will yield a lint error.
    *   `FileScopedDeclarationPrivacy` _(boolean)_: Declarations at file scope with 
        effective private access should be consistently declared as either `fileprivate` 
        or `private`, determined by configuration. Lint: If a file-scoped declaration has 
        formal access opposite to the desired access level in the formatter's 
        configuration, a lint error is raised. Format: File-scoped declarations that have 
        formal access opposite to the desired access level in the formatter's 
        configuration will have their access level changed.
    *   `FullyIndirectEnum` _(boolean)_: If all cases of an enum are `indirect`, the 
        entire enum should be marked `indirect`. Lint: If every case of an enum is 
        `indirect`, but the enum itself is not, a lint error is raised. Format: Enums 
        where all cases are `indirect` will be rewritten such that the enum is marked 
        `indirect`, and each case is not.
    *   `GroupNumericLiterals` _(boolean)_: Numeric literals should be grouped with `_`s 
        to delimit common separators. Specifically, decimal numeric literals should be 
        grouped every 3 numbers, hexadecimal every 4, and binary every 8. Lint: If a 
        numeric literal is too long and should be grouped, a lint error is raised. 
        Format: All numeric literals that should be grouped will have `_`s inserted where 
        appropriate.
    *   `IdentifiersMustBeASCII` _(boolean)_: All identifiers must be ASCII. Lint: If an 
        identifier contains non-ASCII characters, a lint error is raised.
    *   `NeverForceUnwrap` _(boolean)_: Force-unwraps are strongly discouraged and must be 
        documented. Lint: If a force unwrap is used, a lint warning is raised.
    *   `NeverUseForceTry` _(boolean)_: Force-try (`try!`) is forbidden. This rule does 
        not apply to test code. Lint: Using `try!` results in a lint error.
    *   `NeverUseImplicitlyUnwrappedOptionals` _(boolean)_: Implicitly unwrapped optionals 
        (e.g. `var s: String!`) are forbidden. Certain properties (e.g. `@IBOutlet`) tied 
        to the UI lifecycle are ignored. This rule does not apply to test code. Lint: 
        Declaring a property with an implicitly unwrapped type yields a lint error.
    *   `NoAccessLevelOnExtensionDeclaration` _(boolean)_: Specifying an access level for 
        an extension declaration is forbidden. Lint: Specifying an access level for an 
        extension declaration yields a lint error. Format: The access level is removed 
        from the extension declaration and is added to each declaration in the extension; 
        declarations with redundant access levels (e.g. `internal`, as that is the default 
        access level) have the explicit access level removed.
    *   `NoBlockComments` _(boolean)_: Block comments should be avoided in favor of line 
        comments. Lint: If a block comment appears, a lint error is raised.
    *   `NoCasesWithOnlyFallthrough` _(boolean)_: Cases that contain only the `fallthrough` 
        statement are forbidden. Lint: Cases containing only the `fallthrough` statement 
        yield a lint error. Format: The fallthrough `case` is added as a prefix to the 
        next case unless the next case is `default`; in that case, the fallthrough `case` 
        is deleted.
    *   `NoEmptyTrailingClosureParentheses` _(boolean)_: Function calls with no arguments 
        and a trailing closure should not have empty parentheses. Lint: If a function call 
        with a trailing closure has an empty argument list with parentheses, a lint error 
        is raised. Format: Empty parentheses in function calls with trailing closures will 
        be removed.
    *   `NoLabelsInCasePatterns` _(boolean)_: Redundant labels are forbidden in case 
        patterns. In practice, *all* case pattern labels should be redundant. Lint: Using 
        a label in a case statement yields a lint error unless the label does not match 
        the binding identifier.
    *   `NoLeadingUnderscores` _(boolean)_: Identifiers in declarations and patterns 
        should not have leading underscores. This is intended to avoid certain 
        antipatterns; `self.member = member` should be preferred to `member = _member` and 
        the leading underscore should not be used to signal access level. This rule 
        intentionally checks only the parameter variable names of a function declaration, 
        not the parameter labels. It also only checks identifiers at the declaration site, 
        not at usage sites. Lint: Declaring an identifier with a leading underscore yields 
        a lint error.
    *   `NoParensAroundConditions` _(boolean)_: Enforces rules around parentheses in 
        conditions or matched expressions. Parentheses are not used around any condition 
        of an `if`, `guard`, or `while` statement, or around the matched expression in a 
        `switch` statement. Lint: If a top-most expression in a `switch`, `if`, `guard`, 
        or `while` statement is surrounded by parentheses, and it does not include a 
        function call with a trailing closure, a lint error is raised. Format: Parentheses 
        around such expressions are removed, if they do not cause a parse ambiguity. 
        Specifically, parentheses are allowed if and only if the expression contains a 
        function call with a trailing closure.
    *   `NoVoidReturnOnFunctionSignature` _(boolean)_: Functions that return `()` or 
        `Void` should omit the return signature. Lint: Function declarations that 
        explicitly return `()` or `Void` will yield a lint error. Format: Function 
        declarations with explicit returns of `()` or `Void` will have their return 
        signature stripped.
    *   `OneCasePerLine` _(boolean)_: Each enum case with associated values or a raw value 
        should appear in its own case declaration. Lint: If a single `case` declaration 
        declares multiple cases, and any of them have associated values or raw values, a 
        lint error is raised. Format: All case declarations with associated values or raw 
        values will be moved to their own case declarations.
    *   `OneVariableDeclarationPerLine` _(boolean)_: Each variable declaration, with the 
        exception of tuple destructuring, should declare 1 variable. Lint: If a variable 
        declaration declares multiple variables, a lint error is raised. Format: If a 
        variable declaration declares multiple variables, it will be split into multiple 
        declarations, each declaring one of the variables, as long as the result would 
        still be syntactically valid.
    *   `OnlyOneTrailingClosureArgument` _(boolean)_: Function calls should never mix 
        normal closure arguments and trailing closures. Lint: If a function call with a 
        trailing closure also contains a non-trailing closure argument, a lint error is 
        raised.
    *   `OrderedImports` _(boolean)_: Imports must be lexicographically ordered and 
        logically grouped at the top of each source file. The order of the import groups 
        is 1) regular imports, 2) declaration imports, and 3) @testable imports. These 
        groups are separated by a single blank line. Blank lines in between the import 
        declarations are removed. Lint: If an import appears anywhere other than the 
        beginning of the file it resides in, not lexicographically ordered, or  not in the 
        appropriate import group, a lint error is raised. Format: Imports will be 
        reordered and grouped at the top of the file.
    *   `ReturnVoidInsteadOfEmptyTuple` _(boolean)_: Return `Void`, not `()`, in 
        signatures. Note that this rule does *not* apply to function declaration 
        signatures in order to avoid conflicting with `NoVoidReturnOnFunctionSignature`. 
        Lint: Returning `()` in a signature yields a lint error. Format: `-> ()` is 
        replaced with `-> Void`.
    *   `UseEarlyExits` _(boolean)_: Early exits should be used whenever possible. This 
        means that `if ... else { return/throw/break/continue }` constructs should be 
        replaced by `guard ... else { return/throw/break/continue }` constructs in order 
        to keep indentation levels low. Lint: `if ... else { return/throw/break/continue }` 
        constructs will yield a lint error. Format: `if ... else { 
        return/throw/break/continue }` constructs will be replaced with equivalent 
        `guard ... else { return/throw/break/continue }` constructs.
    *   `UseLetInEveryBoundCaseVariable` _(boolean)_: Every variable bound in a `case` 
        pattern must have its own `let/var`. For example, `case let .identifier(x, y)` is 
        forbidden. Use `case .identifier(let x, let y)` instead. Lint: `case let 
        .identifier(...)` will yield a lint error.
    *   `UseShorthandTypeNames` _(boolean)_: Shorthand type forms must be used wherever 
        possible. Lint: Using a non-shorthand form (e.g. `Array<Element>`) yields a lint 
        error unless the long form is necessary (e.g. `Array<Element>.Index` cannot be 
        shortened today.) Format: Where possible, shorthand types replace long form types; 
        e.g. `Array<Element>` is converted to `[Element]`.
    *   `UseSingleLinePropertyGetter` _(boolean)_: Read-only computed properties must use 
        implicit `get` blocks. Lint: Read-only computed properties with explicit `get` 
        blocks yield a lint error. Format: Explicit `get` blocks are rendered implicit by 
        removing the `get`.
    *   `UseSynthesizedInitializer` _(boolean)_: When possible, the synthesized `struct` 
        initializer should be used. This means the creation of a (non-public) memberwise 
        initializer with the same structure as the synthesized initializer is forbidden. 
        Lint: (Non-public) memberwise initializers with the same structure as the 
        synthesized initializer will yield a lint error.
    *   `UseTripleSlashForDocumentationComments` _(boolean)_: Documentation comments must 
        use the `///` form. This is similar to `NoBlockComments` but is meant to prevent 
        documentation block comments. Lint: If a doc block comment appears, a lint error 
        is raised. Format: If a doc block comment appears on its own on a line, or if a 
        doc block comment spans multiple lines without appearing on the same line as code, 
        it will be replaced with multiple doc line comments.
    *   `UseWhereClausesInForLoops` _(boolean)_: `for` loops that consist of a single `if` 
        statement must use `where` clauses instead. Lint: `for` loops that consist of a 
        single `if` statement yield a lint error. Format: `for` loops that consist of a 
        single `if` statement have the conditional of that statement factored out to a 
        `where` clause.
    *   `ValidateDocumentationComments` _(boolean)_: Documentation comments must be 
        complete and valid. "Command + Option + /" in Xcode produces a minimal valid 
        documentation comment. Lint: Documentation comments that are incomplete (e.g. 
        missing parameter documentation) or invalid (uses `Parameters` when there is only 
        one parameter) will yield a lint error.

> TODO: Add support for enabling/disabling specific syntax transformations in
> the pipeline.

### Example

An example `.swift-format` configuration file is shown below.

```javascript
{
    "version": 1,
    "lineLength": 100,
    "indentation": {
        "spaces": 2
    },
    "maximumBlankLines": 1,
    "respectsExistingLineBreaks": true,
    "lineBreakBeforeControlFlowKeywords": true,
    "lineBreakBeforeEachArgument": true
}
```

## API Configuration

The `SwiftConfiguration` module contains a `Configuration` type that is
equivalent to the JSON structure described above. (In fact, `Configuration`
conforms to `Codable` and is how the JSON form is read from and written to
disk.)

The `SwiftFormatter` and `SwiftLinter` APIs in the `SwiftFormat` module take a
mandatory `Configuration` argument that specifies how the formatter should
behave when acting upon source code or syntax trees.

The default initializer for `Configuration` creates a value equivalent to the
default configuration that would be printed by invoking
`swift-format dump-configuration`. API users can also provide their own
configuration by modifying this value or loading it from another source using
Swift's `Codable` APIs.

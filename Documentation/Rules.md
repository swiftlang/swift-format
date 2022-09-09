# `swift-format` Rules

`swift-format` allows users to configure it's rules, both when
used as a command line tool or as an API.

## Command Line Configuration

A `swift-format` configuration file is a JSON file with the following
rule keys and values:

* `AllPublicDeclarationsHaveDocumentation` _(boolean)_: Requires that all public functions, variables, etc. have documentation attached. Default value is false.

* `AlwaysUseLowerCamelCase` _(boolean)_: Enforces variable naming convention to be `lowerCamelCase`. Default value is true.

* `AmbiguousTrailingClosureOverload` _(boolean)_: Default value is true.

* `BeginDocumentationCommentWithOneLineSummary` _(boolean)_: Documentation should have a quick summary at the beginning of the documentation. Default value is false.

* `DoNotUseSemicolons` _(boolean)_: Since Swift does not need semicolons as the end of lines, this rule is enforcing that semicolons are not used. Default value is true.

* `DontRepeatTypeInStaticProperties` _(boolean)_: Default value is true.

* `FileScopedDeclarationPrivacy` _(boolean)_: Default value is true.

* `FullyIndirectEnum` _(boolean)_: Default value is true.

* `GroupNumericLiterals` _(boolean)_: Default value is true.

* `IdentifiersMustBeASCII` _(boolean)_: Default value is true.

* `NeverForceUnwrap` _(boolean)_: Default value is false.

* `NeverUseForceTry` _(boolean)_: Default value is false.

* `NeverUseImplicitlyUnwrappedOptionals` _(boolean)_: Default value is false.

* `NoAccessLevelOnExtensionDeclaration` _(boolean)_: Default value is true.

* `NoBlockComments` _(boolean)_: Use double slash (`// ...`) comments instead of block (`/* ... */`) comments. Default value is true.

* `NoCasesWithOnlyFallthrough` _(boolean)_: Default value is true.

* `NoEmptyTrailingClosureParentheses` _(boolean)_: Default value is true.

* `NoLabelsInCasePatterns` _(boolean)_: Default value is true.

* `NoLeadingUnderscores` _(boolean)_: Created classes and variables names should not start with an underscore. Default value is false.

* `NoParensAroundConditions` _(boolean)_: Parenthesis around conditions are not needed if there are no nested conditions. `if true {}` is preferred over `if (true) {}` Default value is true.

* `NoVoidReturnOnFunctionSignature` _(boolean)_: When function doesn't return anything, it does not need a specified `Void` as return type. Default value is true. `func print() -> Void {}` violates this rule, `func print() {}` does not.

* `OneCasePerLine` _(boolean)_: Default value is true.

* `OneVariableDeclarationPerLine` _(boolean)_: Default value is true.

* `OnlyOneTrailingClosureArgument` _(boolean)_: Default value is true.

* `OrderedImports` _(boolean)_: Import statements should be ordered lexicographically. Default value is true.

* `ReturnVoidInsteadOfEmptyTuple` _(boolean)_: If `NoVoidReturnOnFunctionSignature` is false, enforce the use of `-> Void` instead of `-> ()`. Default value is true.

* `UseEarlyExits` _(boolean)_: Default value is false.

* `UseLetInEveryBoundCaseVariable` _(boolean)_: Default value is true.

* `UseShorthandTypeNames` _(boolean)_: Default value is true.

* `UseSingleLinePropertyGetter` _(boolean)_: Default value is true.

* `UseSynthesizedInitializer` _(boolean)_: If the manually created initializer works identically as the synthesized one, the manually created should be removed. Default value is true.

* `UseTripleSlashForDocumentationComments` _(boolean)_: Use `///` for documentation. Default value is true.

* `UseWhereClausesInForLoops` _(boolean)_: Default value is false.

* `ValidateDocumentationComments` _(boolean)_: Default value is false.

### Example

An example of the rules section of the `.swift-format` configuration file is shown below.

```javascript
"rules" : {
    "AllPublicDeclarationsHaveDocumentation" : false,
    "AlwaysUseLowerCamelCase" : true,
    "AmbiguousTrailingClosureOverload" : true,
    "BeginDocumentationCommentWithOneLineSummary" : false,
    "DoNotUseSemicolons" : true,
    "DontRepeatTypeInStaticProperties" : true,
    "FileScopedDeclarationPrivacy" : true,
    "FullyIndirectEnum" : true,
    "GroupNumericLiterals" : true,
    "IdentifiersMustBeASCII" : true,
    "NeverForceUnwrap" : false,
    "NeverUseForceTry" : false,
    "NeverUseImplicitlyUnwrappedOptionals" : false,
    "NoAccessLevelOnExtensionDeclaration" : true,
    "NoBlockComments" : true,
    "NoCasesWithOnlyFallthrough" : true,
    "NoEmptyTrailingClosureParentheses" : true,
    "NoLabelsInCasePatterns" : true,
    "NoLeadingUnderscores" : false,
    "NoParensAroundConditions" : true,
    "NoVoidReturnOnFunctionSignature" : true,
    "OneCasePerLine" : true,
    "OneVariableDeclarationPerLine" : true,
    "OnlyOneTrailingClosureArgument" : true,
    "OrderedImports" : true,
    "ReturnVoidInsteadOfEmptyTuple" : true,
    "UseEarlyExits" : false,
    "UseLetInEveryBoundCaseVariable" : true,
    "UseShorthandTypeNames" : true,
    "UseSingleLinePropertyGetter" : true,
    "UseSynthesizedInitializer" : true,
    "UseTripleSlashForDocumentationComments" : true,
    "UseWhereClausesInForLoops" : false,
    "ValidateDocumentationComments" : false
}
```

The example `.swift-format` configuration file was created by running `swift-format dump-configuration`.

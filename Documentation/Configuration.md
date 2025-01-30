# `swift-format` Configuration

`swift-format` allows users to configure a subset of its behavior, both when
used as a command line tool or as an API.

## Command Line Configuration

A `swift-format` configuration file is a JSON file with the following
top-level keys and values:

### `version`  
**type:** number  

**description:** The version of the configuration file. For now, this should always be `1`.  

**default:** `1`  

---

### `lineLength`  
**type:** number  

**description:** The maximum allowed length of a line, in characters.  

**default:** `100`  

---

### `indentation`  
**type:** object  

**description:** The kind and amount of whitespace that should be added when indenting one level. The object value of this property should have exactly one of the following properties:  

- `spaces` _(number)_: One level of indentation is the given number of spaces.  
- `tabs` _(number)_: One level of indentation is the given number of tabs.  

**default:** `{ "spaces": 2 }`  

---

### `tabWidth`  
**type:** number  

**description:** The number of spaces that should be considered equivalent to one tab character. This is used during line length calculations when tabs are used for indentation.  

**default:** `8`  

---

### `maximumBlankLines`  
**type:** number  

**description:** The maximum number of consecutive blank lines that are allowed to be present in a source file. Any number larger than this will be collapsed down to the maximum.  

**default:** `1`  

---

### `spacesBeforeEndOfLineComments`  
**type:** number  

**description:** The number of spaces between the last token on a non-empty line and a line comment starting with `//`.  

**default:** `2`  

---

### `respectsExistingLineBreaks`  
**type:** boolean  

**description:** Indicates whether or not existing line breaks in the source code should be honored (if they are valid according to the style guidelines being enforced). If this settings is `false`, then the formatter will be more "opinionated" by only inserting line breaks where absolutely necessary and removing any others, effectively canonicalizing the output.

**default:** `true`  

---

### `lineBreakBeforeControlFlowKeywords`  
**type:** boolean  

**description:** Determines the line-breaking behavior for control flow keywords that follow a closing brace, like `else` and `catch`. If true, a line break will be added before the keyword, forcing it onto its own line. If `false`, the keyword will be placed after the closing brace (separated by a space).

**default:** `false`  

---

### `lineBreakBeforeEachArgument`  
**type:** boolean  

**description:** Determines the line-breaking behavior for generic arguments and function arguments when a declaration is wrapped onto multiple lines. If true, a line break will be added before each argument, forcing the entire argument list to be laid out vertically. If `false`, arguments will be laid out horizontally first, with line breaks only being fired when the line length would be exceeded.

**default:** `false`  

---

### `lineBreakBeforeEachGenericRequirement`  
**type:** boolean  

**description:** Determines the line-breaking behavior for generic requirements when the requirements list is wrapped onto multiple lines. If true, a line break will be added before each requirement, forcing the entire requirements list to be laid out vertically. If `false`, requirements will be laid out horizontally first, with line breaks only being fired when the line length would be exceeded.

**default:** `false`  

---

### `lineBreakBetweenDeclarationAttributes`  
**type:** boolean  

**description:** Determines the line-breaking behavior for adjacent attributes on declarations. If true, a line break will be added between each attribute, forcing the attribute list to be laid out vertically. If `false`, attributes will be laid out horizontally first, with line breaks only being fired when the line length would be exceeded.

**default:** `false`  

---

### `prioritizeKeepingFunctionOutputTogether`  
**type:** boolean  

**description:** Determines if function-like declaration outputs should be prioritized to be together with thefunction signature right (closing) parenthesis. If `false`, function output (i.e. throws, return type) is not prioritized to be together with the signature's right parenthesis, and when the line length would be exceeded,a line break will be fired after the function signature first, indenting the declaration output one additional level. If true, A line break will be fired further up in the function's declaration (e.g. generic parameters, parameters) before breaking on the function's output.  

**default:** `false`  

---

### `indentConditionalCompilationBlocks`  
**type:** boolean  

**description:** Determines if conditional compilation blocks are indented. If this setting is `false` the body of `#if`, `#elseif`, and `#else` is not indented.  

**default:** `true`  

---

### `lineBreakAroundMultilineExpressionChainComponents`  
**type:** boolean  

**description:** Determines whether line breaks should be forced before and after multiline components of dot-chained expressions, such as function calls and subscripts chained together through member access (i.e. "." expressions). When any component is multiline and this option is true, a line break is forced before the "." of the component and after the component's closing delimiter (i.e. right paren, right bracket, right brace, etc.).  

**default:** `false`  

---

## `fileScopedDeclarationPrivacy`
**type:** object

**description:** Declarations at file scope with effective private access should be consistently declared as either `fileprivate` or `private`, determined by configuration.

- `accessLevel` _(string)_: The formal access level to use when encountering a file-scoped declaration with effective private access. Allowed values are `private` and `fileprivate`.

**default:** `{ "accessLevel" : "private" }`  

---

### `indentSwitchCaseLabels`
**type:** boolean

**description:** Determines if `case` statements should be indented compared to the containing `switch` block.

When `false`, the correct form is:
```swift
switch someValue {
case someCase:
  someStatement
...
}
```
When `true`, the correct form is:
```swift
switch someValue {
  case someCase:
    someStatement
  ...
}
```

**default:** `false`

---

### `spacesAroundRangeFormationOperators`  
**type:** boolean  

**description:** Determines whether whitespace should be forced before and after the range formation operators `...` and `..<`.  

**default:** `false`  

---

### `noAssignmentInExpressions`
**type:** object

**description:** Assignment expressions must be their own statements. Assignment should not be used in an expression context that expects a `Void` value. For example, assigning a variable within a `return` statement existing a `Void` function is prohibited.

- `allowedFunctions` _(strings array)_: A list of function names where assignments are allowed to be embedded in expressions that are passed as parameters to that function.

**default:** `{ "allowedFunctions" : ["XCTAssertNoThrow"] }`

---

### `multiElementCollectionTrailingCommas`  
**type:** boolean  

**description:** Determines whether multi-element collection literals should have trailing commas.  

**default:** `true`  

---

### `reflowMultilineStringLiterals`
**type:** `string`

**description:** Determines how multiline string literals should reflow when formatted.

- `never`: Never reflow multiline string literals.
- `onlyLinesOverLength`: Reflow lines in string literal that exceed the maximum line length.
For example with a line length of 10:
```swift
"""
an escape\
 line break
a hard line break
"""
```
will be formatted as:
```swift
"""
an esacpe\
 line break
a hard \
line break
"""
```
- `always`: Always reflow multiline string literals, this will ignore existing escaped newlines in the literal and reflow each line. Hard linebreaks are still respected.
For example, with a line length of 10:
```swift
"""
one \
word \
a line.
this is too long.
"""
```
will be formatted as:
```swift
"""
one word \
a line.
this is \
too long.
"""
```

**default:** `"never"`

---

### `indentBlankLines`  
**type:** boolean  

**description:** Determines whether blank lines should be modified to match the current indentation. When this setting is true, blank lines will be modified whitespace. If `false`, all whitespace in blank lines will be completely removed.

**default:** `false`

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

## Linter and Formatter Rules Configuration

In the `rules` block of `.swift-format`, you can specify which rules to apply
when linting and formatting your project. Read the
[rules documentation](RuleDocumentation.md) to see the list of all
supported linter and formatter rules, and their overview.

You can also run this command to see the list of rules in the default
`swift-format` configuration:

    $ swift-format dump-configuration

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

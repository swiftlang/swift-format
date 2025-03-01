# `swift-format` Ignore/Disable Options

`swift-format` allows users to suppress formatting within a section of source
code. At present, this is only supported on declarations and statements due to
technical limitations of the formatter's implementation. When an ignore comment
is present, the next ["node"](#understanding-nodes) in the source's AST
representation is ignored by the formatter.

## Ignore A File

In the event that an entire file cannot be formatted, add a comment that contains 
`swift-format-ignore-file` at the top of the file and the formatter will leave 
the file completely unchanged.

```swift
// swift-format-ignore-file
import Zoo
import Arrays

struct Foo {
  func foo() { bar();baz(); }
}
```

## Ignoring Formatting (aka indentation, line breaks, line length, etc.)

The formatter applies line length to add line breaks and indentation throughout
source code. When this formatting isn't desired, it can be disabled by prefixing
a declaration or statement with a comment that contains "swift-format-ignore".

```swift
// swift-format-ignore
struct Foo {
	   var bar = true
}

// swift-format-ignore
func foo() {
	    var bar = true
}

// swift-format-ignore
var a = foo+bar+baz
```

Formatting is ignored for all children of the node where the ignore comment is
placed. For example, an ignore comment before a function causes the formatter to
ignore the entire code block of the function and an ignore comment before a
struct or class causes the formatter to ignore all of its members.

## Ignoring Source Transforming Rules

In addition to line breaks and indentation, the formatter provides a number of
rules that apply various source transformations to fix-up common issues in
source code. These rules can be disabled with a similar comment for disabling
formatting. All rules are disabled whenever a "swift-format-ignore" (with no
rule names) comment is encountered. When you want to disable a specific rule or
set of rules, add a comment of the form:

`// swift-format-ignore: [comma delimited list of rule names]`.

```swift
// swift-format-ignore: DoNotUseSemicolons
struct Foo {
	   var bar = true
}

// swift-format-ignore: DoNotUseSemicolons, FullyIndirectEnum, UseEarlyExits
func foo() {
	    var bar = true
}

// swift-format-ignore
var a = foo+bar+baz
```

These ignore comments also apply to all children of the node, identical to the
behavior of the formatting ignore directive described above.

You can also disable specific source transforming rules for an entire file
by using the file-level ignore directive with a list of rule names. For example:

```swift
// swift-format-ignore-file: DoNotUseSemicolons, FullyIndirectEnum
import Zoo
import Arrays

struct Foo {
  func foo() { bar();baz(); }
}
```
In this case, only the DoNotUseSemicolons and FullyIndirectEnum rules are disabled
throughout the file, while all other formatting rules (such as line breaking and 
indentation) remain active.

## Understanding Nodes

`swift-format` parses Swift into an abstract syntax tree, where each element of
the source is represented by a node. Formatting can only be suppressed on
certain "top level nodes" due to limitations of the syntax visitor pattern used
by the formatter. Limiting to these nodes ensures there will be no mismatched
formatting instructions (i.e. start a group without a corresponding end). The
top level nodes that support suppressing formatting are:

- `CodeBlockItemSyntax`, which is either:
  - A single expression (e.g. function call, assignment, expression)
  - A scoped block of code & associated statement(s) (e.g. function declaration,
    struct/class/enum declaration, if/guard statements, switch statement, while
    loop). All code nested syntactically inside of the ignored node is also
    ignored by the formatter. This means ignoring a struct declaration also
    ignores all code inside of the struct declaration.
- `MemberDeclListItemSyntax`
  - Any member declaration inside of a declaration (e.g. properties and
    functions declared inside of a struct/class/enum). All code nested
    syntactically inside of the ignored node is also ignored by the formatter.

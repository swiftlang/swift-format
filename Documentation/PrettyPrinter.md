# swift-format Pretty Printer

## Introduction

The algorithm used in the swift-format pretty printer is based on (but not a
strict implementation of) the "simple" version of the algorithm described by
Derek Oppen in his paper
[*Pretty Printing*](http://i.stanford.edu/pub/cstr/reports/cs/tr/79/770/CS-TR-79-770.pdf)
(1979).

It employs two functions: *scan* and *print*. The *scan* function
accepts a stream of tokens and calculates the lengths of these tokens. It then
passes the tokens and their computed lengths to *print*, which handles the
actual printing of the tokens, automatically inserting line breaks and indents
to obey a given maximum line length. We describe in detail how these functions
have been implemented in swift-format.

## Tokens

### Token Groups

It is often necessary to group a series of tokens together into logical groups
that we want to avoid splitting with line break if possible. The algorithm tries
to break as few groups as possible when printing. Groups begin with *open*
tokens and end with *close* tokens. These tokens must always be paired.

### Token Types

The different types of tokens are represented as a Token `enum` within the code.
The available cases are: `syntax`, `break`, `spaces`, `open`, `close`,
`newlines`, `comment`, and `verbatim`. The behavior of each of them is
described below with pseudocode examples.

See: [`Token.swift`](../Sources/SwiftFormat/PrettyPrint/Token.swift)

#### Syntax

The *syntax* tokens contain the segments of text that need to be printed (e.g.
`}`, `func`, `23`, `while`, etc.). The length of a token is the number of
columns needed to print it. For example, `func` would have a length of 4.

#### Break

The *break* tokens indicate where line breaks are allowed to occur. These
frequently occur as the whitespace in between syntax tokens. The breaks contain
three associated values that can be specified when creating the break token:

* *kind:* Indicates the behavior of the break. These are described in more
  detail below.
* *size:* The number of spaces that should be printed when the line does *not*
  break at this location.
* *ignoresDiscretionary:* If false (the default), and if the pretty printer is
  configured to respect the user's existing line breaks (referred to as
  "discretionary" line breaks), then a break will be forced at this location.
  If true, then the user's discretionary line break will be removed.

The length of a break is its size plus the length of the token that immediately
comes after it. If a break immediately precedes a group, its length will be its
size plus the size of the group.

##### Break kinds

The break's "kind" defines the behavior of the break---specifically, the
indentation behavior that occurs when line wrapping occurs at its location.
There are five kinds of breaks:

* *open:* If line wrapping occurs here, then the base indentation level of
  subsequent tokens increases by one unit until the corresponding `close` break
  is encountered.

  _This should not be confused with an open group token._

* *close:* If line wrapping occurs here, the base indentation level returns to
  the value it had before the matching `open` break.

  This kind of break has an associated value, `mustBreak`. If true (the
  default), then this break will always wrap when it occurs on a different line
  than its matching `open` break, even if the length of the break would allow
  it to fit on the same line. This is the behavior one typically wants when
  laying out curly-brace delimited blocks or collection literals. If this value
  is false, then the break only wraps when necessary. This behavior is
  desirable, for example, if you want the closing parenthesis of a function
  call to occur on the same line as the final argument.

  _This should not be confused with a close group token._

* *continue:* If line wrapping occurs here, the following line will be treated
  as a continuation line (indented one unit further than the base level),
  without changing the base level. These are used when wrapping something that
  isn't "scoped" (like an argument list between delimiters), but instead
  something "open-ended" like a long expression.

* *same:* If line wrapping occurs here, the following line will be indented at
  the same indentation level as the previous line. This is used, for example,
  when breaking comma-delimited lists.

* *reset:* If a reset break occurs on a continuation line, the line will always
  wrap (without regard to the break's length) and the indentation level will be
  reset to the base indentation level. This is used, for example, to reset the
  indentation level at the end of a statement (which may have been wrapped as
  a continuation) or to force the `{` of a control flow statement onto its own
  line when the statement was wrapped.

#### Open

An *open* token indicates the start of a group.

```
# break(.same, 1)
Token = ["one", break, open, "two", break, "three", break, open, "four", break, "five", close, close]

# Maximum line length of 20
Output =
"""
one
two three four five
"""

# Maximum line length of 10
Output =
"""
one
two three
four five
"""
```

Open tokens have a *break style*. The break style is either *consistent* or
*inconsistent*. If a group is too large to fit on the remaining space on a
line, and it is labeled as *consistent*, then the break tokens it contains will
all produce line breaks. (In the case of nested groups, the break style only
affects a group's immediate children.) The default behavior is *inconsistent*,
in which case the break tokens only produce line breaks when their lengths
exceed the remaining space on the line.

```
# open(consistent/inconsistent)
Tokens = ["one", break(.same, 1), open(C), "two", break(.same, 1), "three", close]

# Maximum line length of 10 (consistent breaking)
Output =
"""
one
two
three
"""

# With inconsistent breaking
Tokens = ["one", break(.same, 1), open(I), "two", break(.same, 1), "three", close]
Output =
"""
one
two three
"""
```

The open token of a group is assigned the total size of the group as its length.
Open tokens must always be paired with a *close* token.

```
Tokens = ["one", break(.same, 1), open(C), "two", break(.same, 1), "three", close]
Lengths = [3, 11, 10, 3, 1, 5, 0]
```

#### Close

The *close* tokens indicate the end of a group, and they have a length of zero.
They must always be paired with an *open* token.

#### Newline

The *newline* tokens behave much the same way as *break* tokens, except that
they always produce a line break. They can be given an integer number of line
breaks to produce (which is one by default).

Newline tokens also have a `discretionary` flag. If true, then the newline is
one that represents a newline that the user originally had written in their
code. If false, then it represents one that the formatter itself added to the
token stream.

These tokens are given a length equal to the maximum allowed line width. The
reason for this is to indicate that any enclosing groups are too large to fit on
a single line.

```
# Assume maximum line length of 50
# break(size)
Tokens = ["one", break(1), "two", break(1), open, "three", newline, "four", close]
Lengths = [3, 4, 3, 60, 59, 5, 50, 4, 0]
```

#### Space

*Space* tokens are used to insert whitespace between tokens, as you might do
with a *break* token. However, line-breaks may not occur at *space* tokens;
thus, they can be used to keep neighboring tokens "glued" together under any
circumstances.

Space tokens have a size assigned to them, corresponding to the number of
spaces you wish to print. They also have a `flexible` flag, which if true,
allows neighboring space tokens to be collapsed together so that the number
of spaces printed is the maximum of the pair.

#### Comment

Comment tokens represent Swift source comments, and they come in four types:
`line`, `docLine`, `block`, and `docBlock`. Their length is equal to the number
of characters needed to print them, including whitespace and delimiters. Line
comments produce one comment token per line. If other comment types span
multiple lines, their content is represented as a single comment token.

```
# Line comment
// comment 1
// comment 2
Tokens = [line(" comment 1"), newline, line(" comment 2")]

/// Doc comment 1
/// Second line
Tokens = [docLine(" Doc comment 1\n Second line")]

/* Block comment
   Second line */
Tokens = [block(" Block comment\n   Second Line ")]

/** Doc Block comment
  * Second line **/
Tokens = [docBlock(" Doc Block comment\n  * Second line *")]
```

#### Verbatim

Verbatim tokens are used to print text verbatim without any formatting apart
from applying a global indentation. They have a length set to the maximum line
width. They are typically used to handle syntax types that are classed as
"unexpected" by SwiftSyntax. In these cases, we don't have access to the
substructure of the syntax node a manner useful for formatting, so we print them
verbatim. The indentation for verbatim tokens is applied to the first line of
the text. The relative indentation of subsequent lines is preserved unless they
have less indentation than the first line, in which case we set the indentation
of those lines equal to the first.

```
// Consider "ifnt", an unexpected syntax structure:

if someCondition {
    ifnt anotherCondition {
      let a = 123
  let b = 456
    }
}

// The pretty-printer will transform this into:

if someCondition {
  ifnt anotherCondition {
    let a = 123
  let b = 456
  }
}
```

### Token Generation

Token generation begins with the abstract syntax tree (AST) of the Swift source
file, provided by the [SwiftSyntax](https://github.com/swiftlang/swift-syntax)
library. We have overloaded a `visit` method for each of the different kinds of
syntax nodes. Most of these nodes are higher-level, and are composed of other
nodes. For example, `FunctionDeclSyntax` contains
`GenericParameterClauseSyntax`, `FunctionSignatureSyntax` nodes among others.
These member nodes are called via a call to `super.visit` at the end of the
function. That being said, we visit the higher level nodes before the lower
level nodes.

Within the visit methods, you can attach pretty-printing tokens at different
points within the syntax structures. For example, if you wanted to indent the
contents of a curly brace structure, you might do something like:

```
// In arrangeBracesAndContents:
after(node.leftBrace, tokens: .break(.open, size: 1), .open)
before(node.rightBrace, tokens: .break(.close, size: 1), .close)
```

Two dictionaries are maintained to keep track of the pretty-printing tokens
attached to the syntax tokens: `beforeMap`, and `afterMap`. Calls to `before`
and `after` populate these dictionaries. In the above example, `node.body?` may
return `nil`, in which case `before` and `after` gracefully do nothing.

The lowest level in the AST is `TokenSyntax`, and it is at this point that we
actually add the syntax token and its attached pretty-printer tokens to the
output array. This is done in `visit(_ token: TokenSyntax)`. We first check the
syntax token's leading trivia for the presence of newlines and comments
(excluding end-of-line comments), and add corresponding printing tokens to the
output array. Next, we look at the token's entry in the `beforeMap` dictionary
and add any accumulated `before` tokens to the output array. Next, we add the
syntax token itself to the array. We look ahead to the leading trivia of the
next syntax token to check for an end-of-line comment, and we add it to the
array if needed. Finally, we add the `after` tokens. The ordering of the `after`
tokens is adjusted such that the token attached by lower level `visit` method
are added to the array before the higher level `visit` methods.

The only types of trivia we are interested in are newlines and comments. Since
these only appear as leading trivia, we don't need to look at trailing trivia.
It is important to note that `SwiftSyntax` always attaches comments as the
leading trivia on the following token.  Spaces are handled directly by inserting
`break` and `space` tokens.

When examining trivia for comments, a distinction is made for end-of-line
comments:

```
// not end-of-line
let a = 123  // end-of-line comment
let b = "abc"

// In the above example, "not end-of-line" is part of the leading trivia of
// "let" for "let a", and "end-of-line comment" is leading trivia for "let" of
// "let b".
```

A comment is determined to be end-of-line when it appears as the first item in a
token's leading trivia (it is not preceded by a newline, and we are not at the
beginning of a source file).

When we have visited all nodes in the AST, the array of printing tokens is then
passed on to the *scan* phase of the pretty-printer.

See: [`TokenStreamCreator.swift`](../Sources/SwiftFormat/PrettyPrint/TokenStreamCreator.swift)

## Scan

The purpose of the scan phase is to calculate the lengths of all tokens;
primarily the `break` and `open` tokens. It takes as input the array of tokens
produced by `TokenStreamCreator`.

There are three main variables used in the scan phase: an index stack
(`delimIndexStack`), a running total of the lengths (`total`), and an array of
lengths (`lengths`). The index stack is used to store the locations of `open`
and `break` tokens, since we need to look back to fill in the lengths. The
running total adds the lengths of each token as we encounter it. The length
array is the same size as the token array, and stores the computed lengths of
the tokens.

After having iterated over the entire list of tokens and calculated their
lengths, we then loop over the tokens and call `print` for each token with its
corresponding length.

See: [`PrettyPrint.swift:prettyPrint()`](../Sources/SwiftFormat/PrettyPrint/PrettyPrint.swift)

### Syntax Tokens

The length of a `syntax` token is the number of columns needed to print it. This
value goes directly into the length array, and `total` is incremented by the
same amount.

### Open Tokens

If we encounter an `open` token, we push its index onto `delimIndexStack`,
initialize its length to `-total`, and append this value to the length array.

### Close Tokens

At a `close` token, we pop an index off the top of the stack. This index will
correspond to either an `open` or `break` token. If it is an `open` token, we
add `total` to its length. The `total` variable will have been accumulating
lengths since encountering the `open` token. The `open` token's length is
`total_at_close - total_at_open` (hence the reason for initializing to
`-total`).

If the index is a `break`, we add `total` to its length. We pop the stack again
to get the location of the `open` token corresponding to this `close`. We are
guaranteed for this to be an `open` since any other `break` tokens will have
been handled by the logic in the next subsection.

### Break Tokens

If a `break` token is encountered, first check the top of the index stack. Only
if the index corresponds to another `break`, pop it from the stack, and add
`total` to its length. Initialize the length of the current `break` to `-total`
on the length array, push its index onto the stack, and then increment `total`
by the size of the `break`.

### Newline Tokens

A `newline` token executes the same logic as for `break` tokens. However, we
assign it a length equal to the maximum allowed line length, and increment
`total` by the same amount. We do not push its index onto the stack since we
already know its length and do not need to calculate it at a later time.

### Space Tokens

A `space` token has a length equal to its `size` value. This is appended to the
length array and added to `total`.

### Reset Tokens

If a `reset` token is encountered, check if the top of the index stack
corresponds to a `break`. If it does, pop it from the stack, and add `total` to
its length in the length array. Append a length of 0 to the length array for the
`reset` token.

### Comment Tokens

A `comment` token has a length equal to the number of characters required to
print it. This value is appended to the length array, and added to `total`.

### Verbatim Tokens

A `verbatim` token has a length equal to the maximum allowed line length. This
value is appended to the length array, and added to `total`.

## Print

The purpose of the *print* phase is to print the contents of a syntax node to
the console or to append it to a string buffer as we do in swift-format. It
tracks the remaining space left on the line, and it decides whether or not to
insert a line break based on the length of the token.

The logic for the `print` function is fairly complex and varies depending on
the kind of token or break being printed. Rather than explain it here, we
recommend viewing its documented source directly.

See: [`PrettyPrint.swift:printToken(...)`](../Sources/SwiftFormat/PrettyPrint/PrettyPrint.swift)

## Differences from Oppen's Algorithm

For those who might already be familiar with Oppen's pretty-printing algorithm,
described below are ways in which swift-format's pretty-printer differs from
Oppen's.

### Absence of a "stream"

Oppen's algorithm was designed to run like a server. It accepts tokens one at a
time ad infinitum, so it requires a buffer to accumulate tokens. It prints them
out as it goes along. All of swift-format's tokens are already available as an
array in memory, so we don't need a buffer. We access the token array directly,
rather than using a separate `stream`.

### Use of the "simple" rather than the "optimized" algorithm

Oppen's simple algorithm has to wait until `break` and `open` tokens have their
lengths calculated before it can start printing. The buffer could conceivably
get quite large before anything can be printed. The optimized algorithm allows
you to start printing tokens much sooner, and optimizes the size of the buffer.
Because we aren't accumulating tokens in a buffer, we don't benefit from the
optimized (and more complicated) algorithm.

### "Break" instead of "Blank"

What Oppen refers to as "blanks", we call "breaks". The change was made since,
arguably, "break" better describes the token's function than "blank".

### `newline` tokens

Oppen used "blanks" as catch-all tokens for spaces and line breaks. Indeed,
`newlines` behave almost identically to `break` tokens with a size of
`maximumLineWidth`. However, unlike `break` tokens, the `newline` size is fixed,
and does not depend on what follows it.

### Semantic breaks

When Oppen encounters `open` tokens, he pushes the location of the token onto
the indentation stack. It produces something that looks like this:

```swift
myFunc(one,  // Assuming an open token occurs after the "("
       two,
       three)
```

We don't dynamically compute our indentation levels in this way, since we use
configurable fixed indentation steps.

Instead, we control ours explicitly through the use of semantic `break` tokens.
Rather than associate a fixed offset with each break, we describe the
_behavior_ of the break and the printing algorithm updates the indentation
differently depending on that behavior. This increases the complexity of the
`print` algorithm somewhat, but significantly improves the expressibility of
the `visit` methods that populate the token stream.

### Consistent breaking on `open` tokens

We specify the consistent breaking condition on the `open` tokens rather than on
the `break` tokens, whereas Oppen specifies the condition on the `break` tokens.
`break` tokens that break consistently are grouped together, so it made more
sense to place this label on the containing group.

### Deferring whitespace until printing text

Oppen's algorithm prints the indentation whitespace when `break` tokens are
encountered. If we have extra blank lines in between source code, this can
result in hanging or trailing whitespace. Waiting to print the indentation <!--# ignore-unacceptable-language -->
whitespace until encountering a `syntax`, `comment, or `verbatim` tokens
prevents this.

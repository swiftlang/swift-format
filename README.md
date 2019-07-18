# swift-format

`swift-format` provides the formatting technology for
[SourceKit-LSP](https://github.com/apple/sourcekit-lsp) and the building
blocks for doing code formatting transformations.

This package can be used as a [command line tool](#command-line-usage)
or linked into other applications as a Swift Package Manager dependency and
invoked via an [API](#api-usage).

> NOTE: No default Swift code style guidelines have yet been proposed. The
> style that is currently applied by `swift-format` is just one possibility,
> and the code is provided so that it can be tested on real-world code and
> experiments can be made by modifying it.

## Command Line Usage

> NOTE: `swift-format` currently uses the standalone Swift parser that
> requires a Swift 5.1 or higher. The version of the toolchain used must
> match the version of `SwiftSyntax` listed in
> [Package.swift](Package.swift) (or be the most recent version before it,
> if there is not an exact match).

```
swift-format [OPTIONS] FILE...
```

The `swift-format` tool can be invoked with one or more `.swift` source files,
as well as the following command line options:

* `-v/--version`: Prints the `swift-format` version and exits.

* `-m/--mode <format|lint|dump-configuration>`: The mode in which to run
  `swift-format`. The `format` mode formats source files. The `lint` mode
  only prints diagnostics indicating style violations. The `dump-configuration`
  mode dumps the default `swift-format` configuration to standard output.

  If unspecified, the default mode is `format`.

* `--configuration <file>`: The path to a JSON file that contains
  [configurable settings](#configuration) for `swift-format`. If omitted, a
  default configuration is use (which can be seen by running
  `--mode dump-configuration`).

* `-i/--in-place`: Overwrites the input files when formatting instead of
  printing the results to standard output.

### Configuration

For any source file being checked or formatted, `swift-format` looks for a
JSON-formatted file named `.swift-format` in the same directory. If one is
found, then that file is loaded to determine the tool's configuration. If the
file is not found, then it looks in the parent directory, and so on.

If no configuration file is found, a default configuration is used. The
settings in the default configuration can be viewed by running
`swift-format --mode dump-configuration`, which will dump it to standard
output.

If the `--configuration <file>` option is passed to `swift-format`, then that
configuration will be used unconditionally and the file system will not be
searched.

See [Documentation/Configuration.md](Documentation/Configuration.md) for a
description of the configuration file format and the settings that are
available.

## API Usage

`swift-format` can be easily integrated into other tools written in Swift.
Instead of invoking the formatter by spawning a subprocess, users can depend on
`swift-format` as a Swift Package Manager dependency and import the
`SwiftFormat` module, which contains the entry points into the formatter's
diagnostic and correction behavior.

Formatting behavior is provided by the `SwiftFormatter` class and linting
behavior is provided by the `SwiftLinter` class. These APIs can be passed
either a Swift source file `URL` or a `Syntax` node representing a
SwiftSyntax syntax tree. The latter capability is particularly useful for
writing code generators, since it significantly reduces the amount of trivia
that the generator needs to be concerned about adding to the syntax nodes it
creates. Instead, it can pass the in-memory syntax tree to the `SwiftFormat`
API and receive perfectly formatted code as output.

Please see the documentation in the
[`SwiftFormatter`](Sources/SwiftFormat/SwiftFormatter.swift) and
[`SwiftLinter`](Sources/SwiftFormat/SwiftLinter.swift) classes for more
information about their usage.

## Development

If you are interested in developing `swift-format`, there is additional
documentation about that [here](Documentation/Development.md).

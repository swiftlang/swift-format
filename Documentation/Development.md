# Developing `swift-format`

## Keeping the Pipeline and Tests Updated

Since Swift does not yet have a runtime reflection system, we use code
generation to keep the linting/formatting pipeline up-to-date. If you add or
remove any rules from the `SwiftFormatRules` module, or if you add or remove
any `visit` methods from an existing rule in that module, you must run the
`generate-pipeline` tool update the pipeline and configuration sources.

The easiest way to do this is to run the following command in your terminal:

```shell
swift run generate-pipeline
```

If successful, this tool will update
`Sources/SwiftFormatConfiguration/RuleRegistry+Generated.swift` and
`Sources/SwiftFormat/Pipelines+Generated.swift`.

Likewise, you should keep the Linux XCTest manifests updated if you add or
remove any tests from `swift-format` by running the following command in your
terminal:

```shell
swift test --generate-linuxmain
```

## Command Line Options for Debugging

`swift-format` provides some hidden command line options to facilitate
debugging the tool during development:

* `--debug-disable-pretty-print`: Disables the pretty-printing pass of the
  formatter, causing only the syntax tree transformations in the first phase
  pipeline to run.

* `--debug-dump-token-stream`: Dumps a human-readable indented structure
  representing the pseudotoken stream constructed by the pretty printing
  phase.

## Support Scripts

The [Scripts](../Scripts) directory contains a `format-diff.sh` script
that some developers may find useful. When invoked, it rebuilds
`swift-format` (if necessary to pick up any recent changes) and lets
you view a side-by-side `diff` with the original file on the left side
and the formatted output on the right side.

This script will use `colordiff` if it is installed on your `PATH`;
otherwise, it will fall back to `diff`.

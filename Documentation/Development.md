# Developing `swift-format`

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

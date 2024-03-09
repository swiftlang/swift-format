# Using Swift-format within Swift Package Manager
===
`swift-format` can be used as a plugin within the swift package manager, relatively simply.

# Package.swift setup

All you need to do is add the correct package dependency:

```swift
  .package(
    url: "https://github.com/apple/swift-format.git",
    from: "508.0.1"
  )
```

This will add two package plugins to your build:

* `format-source-code` applies the formatter to specified targets
* `lint-source-code` applies the linter to the targets

invoke the format plugin by calling

```zsh
 swift package format-source-code --target=$TARGET
```

where `$TARGET` is the name of the build target in your Package file you want to format. 


Similarly, invoke the lint plugin by calling

```zsh
    swift package lint-source-code --target=$TARGET
```

You can add a custom configuration by setting the `--configurationPath=$CONFIG_FILE` value. For example, if youre configuration is in `.swift-format`, then 

```zsh
    swift package format-source-code --target=$TARGET --configurationPath=.swift-format
```
will apply the configuration specified in `.swift-format` to all the swift sources in `$TARGET`.


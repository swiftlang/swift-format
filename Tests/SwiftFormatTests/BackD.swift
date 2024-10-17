final class BackDeployAttributeTests: PrettyPrintTestCase {
  func testSpacingAndWrapping() {
    let input =
      """
      @backDeployed(before:iOS 17)
      public func hello() {}

      @backDeployed(before:iOS  17,macOS   14)
      public func hello() {}

      @backDeployed(before:iOS  17,macOS   14,tvOS     17)
      public func hello() {}
      """

    let expected80 =
      """
      @backDeployed(before: iOS 17)
      public func hello() {}

      @backDeployed(before: iOS 17, macOS 14)
      public func hello() {}

      @backDeployed(before: iOS 17, macOS 14, tvOS 17)
      public func hello() {}

      """

    assertPrettyPrintEqual(input: input, expected: expected80, linelength: 80)

    let expected28 =
      """
      @backDeployed(
        before: iOS 17
      )
      public func hello() {}

      @backDeployed(
        before: iOS 17, macOS 14
      )
      public func hello() {}

      @backDeployed(
        before:
          iOS 17, macOS 14,
          tvOS 17
      )
      public func hello() {}

      """

    assertPrettyPrintEqual(input: input, expected: expected28, linelength: 28)
  }
}

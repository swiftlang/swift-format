import SwiftFormatConfiguration

public class ObjectLiteralExprTests: PrettyPrintTestCase {

  public func testColorLiteral_noPackArguments() {
    let input =
      """
      #colorLiteral()
      #colorLiteral(red: 1.0)
      #colorLiteral(red: 1.0, green: 1.0)
      #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
      """

    let expected =
      """
      #colorLiteral()
      #colorLiteral(red: 1.0)
      #colorLiteral(
        red: 1.0,
        green: 1.0
      )
      #colorLiteral(
        red: 1.0,
        green: 1.0,
        blue: 1.0,
        alpha: 1.0
      )

      """

    var config = Configuration()
    config.lineBreakBeforeEachArgument = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 25, configuration: config)
  }

  public func testColorLiteral_packArguments() {
    let input =
      """
      #colorLiteral()
      #colorLiteral(red: 1.0)
      #colorLiteral(red: 1.0, green: 1.0)
      #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
      """

    let expected =
      """
      #colorLiteral()
      #colorLiteral(red: 1.0)
      #colorLiteral(
        red: 1.0, green: 1.0)
      #colorLiteral(
        red: 1.0, green: 1.0,
        blue: 1.0, alpha: 1.0)

      """

    var config = Configuration()
    config.lineBreakBeforeEachArgument = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 25, configuration: config)
  }

  public func testImageLiteral_noPackArguments() {
    let input =
      """
      #imageLiteral()
      #imageLiteral(resourceName: "foo.png")
      #imageLiteral(resourceName: "foo/bar/baz/qux.png")
      #imageLiteral(resourceName: "foo/bar/baz/quux.png")
      """

    let expected =
      """
      #imageLiteral()
      #imageLiteral(resourceName: "foo.png")
      #imageLiteral(
        resourceName: "foo/bar/baz/qux.png"
      )
      #imageLiteral(
        resourceName: "foo/bar/baz/quux.png"
      )

      """

    var config = Configuration()
    config.lineBreakBeforeEachArgument = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 38, configuration: config)
  }

  public func testImageLiteral_packArguments() {
    let input =
      """
      #imageLiteral()
      #imageLiteral(resourceName: "foo.png")
      #imageLiteral(resourceName: "foo/bar/baz/qux.png")
      #imageLiteral(resourceName: "foo/bar/baz/quux.png")
      """

    let expected =
      """
      #imageLiteral()
      #imageLiteral(resourceName: "foo.png")
      #imageLiteral(
        resourceName: "foo/bar/baz/qux.png")
      #imageLiteral(
        resourceName: "foo/bar/baz/quux.png"
      )

      """

    var config = Configuration()
    config.lineBreakBeforeEachArgument = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 38, configuration: config)
  }
}

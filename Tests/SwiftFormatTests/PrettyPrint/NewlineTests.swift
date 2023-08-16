final class NewlineTests: PrettyPrintTestCase {
  func testLeadingNewlines() {
    let input =
      """


      let a = 123
      """

    let expected =
      """
      let a = 123

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45)
  }

  func testLeadingNewlinesWithComments() {
    let input =
      """


      // Comment

      let a = 123
      """

    let expected =
      """
      // Comment

      let a = 123

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45)
  }

  func testTrailingNewlines() {
    let input =
      """
      let a = 123


      """

    let expected =
      """
      let a = 123

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45)
  }

  func testTrailingNewlinesWithComments() {
    let input =
      """
      let a = 123

      // Comment


      """

    let expected =
      """
      let a = 123

      // Comment

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45)
  }

  func testNewlinesBetweenMembers() {
    let input =
      """


      class MyClazz {

        lazy var memberView: UIView = {
          let view = UIView()
          return view
        }()


        func doSomething() {
          print("!")
        }


        func doSomethingElse() {
          print("else!")
        }


        let constMember = 1



      }
      """

    let expected =
      """
      class MyClazz {

        lazy var memberView: UIView = {
          let view = UIView()
          return view
        }()

        func doSomething() {
          print("!")
        }

        func doSomethingElse() {
          print("else!")
        }

        let constMember = 1

      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 100)
  }
}

import SwiftFormat

final class MemberAccessExprTests: PrettyPrintTestCase {
  func testMemberAccess() {
    let input =
      """
      let a = one.two.three.four.five
      let b = (c as TypeD).one.two.three.four
      """

    let expected =
      """
      let a = one.two
        .three.four
        .five
      let b =
        (c as TypeD)
        .one.two
        .three.four

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 15)
  }

  func testImplicitMemberAccess() {
    let input =
      """
      let array = [.first, .second, .third]
      """

    let expected =
      """
      let array = [
        .first,
        .second,
        .third,
      ]

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 15)
  }

  func testMethodChainingWithClosures() {
    let input =
      """
      let result = [1, 2, 3, 4, 5]
          .filter{$0 % 2 == 0}
          .map{$0 * $0}
      """

    let expected =
      """
      let result = [1, 2, 3, 4, 5]
        .filter { $0 % 2 == 0 }
        .map { $0 * $0 }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 30)
  }

  func testMethodChainingWithClosuresFullWrap() {
    let input =
      """
      let result = [1, 2, 3, 4, 5].filter { $0 % 2 == 0 }.map { $0 * $0 }
      array.filter { $0 }.map { $0 as FooBarBaz }.compactMap { $0 }
      array.filter {
        $0 is FooBarBaz
      }.map { $0 as FooBarBaz }.compactMap { $0 }
      """

    let expectedNoForcedBreaks =
      """
      let result = [
        1, 2, 3, 4, 5,
      ].filter {
        $0 % 2 == 0
      }.map { $0 * $0 }
      array.filter { $0 }
        .map {
          $0 as FooBarBaz
        }.compactMap {
          $0
        }
      array.filter {
        $0 is FooBarBaz
      }.map {
        $0 as FooBarBaz
      }.compactMap { $0 }

      """

    assertPrettyPrintEqual(input: input, expected: expectedNoForcedBreaks, linelength: 20)

    let expectedWithForcedBreaks =
      """
      let result = [
        1, 2, 3, 4, 5,
      ]
      .filter {
        $0 % 2 == 0
      }
      .map { $0 * $0 }
      array.filter { $0 }
        .map {
          $0 as FooBarBaz
        }
        .compactMap { $0 }
      array.filter {
        $0 is FooBarBaz
      }
      .map {
        $0 as FooBarBaz
      }
      .compactMap { $0 }

      """

    var configuration = Configuration.forTesting
    configuration.lineBreakAroundMultilineExpressionChainComponents = true
    assertPrettyPrintEqual(
      input: input,
      expected: expectedWithForcedBreaks,
      linelength: 20,
      configuration: configuration
    )
  }

  func testContinuationRestorationAfterGroup() {
    let input =
      """
      someLongReceiverName.someEvenLongerMethodName {
      }

      someLongReceiverName.someEvenLongerMethodName {
        bar()
        baz()
      }
      """

    let expected =
      """
      someLongReceiverName
        .someEvenLongerMethodName {
        }

      someLongReceiverName
        .someEvenLongerMethodName {
          bar()
          baz()
        }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 30)
  }

  func testOperatorChainedMemberAccessExprs() {
    let input =
      """
      let totalHeight = Constants.textFieldHeight + Constants.borderHeight + Constants.importantLabelHeight
      """

    let expected =
      """
      let totalHeight =
        Constants.textFieldHeight + Constants.borderHeight
        + Constants.importantLabelHeight

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 60)
  }

  func testBaselessMemberAccess() {
    let input =
      """
      foo.bar(.someImplicitlyTypedMemberFunc(
        a, b, c))
      """

    let expected =
      """
      foo.bar(
        .someImplicitlyTypedMemberFunc(
          a, b, c))

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 60)
  }

  func testChainsUsingNonTrailingClosures() {
    let input =
      """
      myWeirdFunc(foo: bar, withClosure: { abc in
        abc.frob() }).map { $0 }.filter { $0.isFrobbed }
      myWeirdFunc(withClosure: { abc in
        abc.frob() }).map { $0 }.filter { $0.isFrobbed }

      """

    let expectedNoForcedBreaking =
      """
      myWeirdFunc(
        foo: bar,
        withClosure: { abc in
          abc.frob()
        }
      ).map { $0 }.filter {
        $0.isFrobbed
      }
      myWeirdFunc(withClosure: { abc in
        abc.frob()
      }).map { $0 }.filter {
        $0.isFrobbed
      }

      """

    assertPrettyPrintEqual(input: input, expected: expectedNoForcedBreaking, linelength: 35)

    let expectedWithForcedBreaking =
      """
      myWeirdFunc(
        foo: bar,
        withClosure: { abc in
          abc.frob()
        }
      )
      .map { $0 }.filter { $0.isFrobbed }
      myWeirdFunc(withClosure: { abc in
        abc.frob()
      })
      .map { $0 }.filter { $0.isFrobbed }

      """

    var configuration = Configuration.forTesting
    configuration.lineBreakAroundMultilineExpressionChainComponents = true
    assertPrettyPrintEqual(
      input: input,
      expected: expectedWithForcedBreaking,
      linelength: 35,
      configuration: configuration
    )
  }

  func testMemberItemClosureChaining() {
    let input =
      """
      struct ContentView: View {
        var body: some View {
          VStack(alignment: .leading) {
            Text("Turtle Rock")
              .headlineTextRenderingFont(.title)
            HStack {
              Text("Joshua Tree National Park")
                .font(.subheadline) { Color(.blue) }
                .bold(true)
            }
            Image(.turtle) {
              presentTurtle()
            }.foreground[tintColors]
            Image(.swiftyBird) {
              presentBirds()
            }
            .highlight[tintColors]
          }
          .padding(10)
          Text("Rabbit Rock") { Font(.serifs) }
            .backgroundColor(.red)
        }
      }
      """

    let expectedNoForcedBreaks =
      """
      struct ContentView: View {
        var body: some View {
          VStack(alignment: .leading) {
            Text("Turtle Rock")
              .headlineTextRenderingFont(.title)
            HStack {
              Text("Joshua Tree National Park")
                .font(.subheadline) { Color(.blue) }
                .bold(true)
            }
            Image(.turtle) {
              presentTurtle()
            }.foreground[tintColors]
            Image(.swiftyBird) {
              presentBirds()
            }
            .highlight[tintColors]
          }
          .padding(10)
          Text("Rabbit Rock") { Font(.serifs) }
            .backgroundColor(.red)
        }
      }

      """

    assertPrettyPrintEqual(input: input, expected: expectedNoForcedBreaks, linelength: 50)

    let expectedWithForcedBreaks =
      """
      struct ContentView: View {
        var body: some View {
          VStack(alignment: .leading) {
            Text("Turtle Rock")
              .headlineTextRenderingFont(.title)
            HStack {
              Text("Joshua Tree National Park")
                .font(.subheadline) { Color(.blue) }
                .bold(true)
            }
            Image(.turtle) {
              presentTurtle()
            }
            .foreground[tintColors]
            Image(.swiftyBird) {
              presentBirds()
            }
            .highlight[tintColors]
          }
          .padding(10)
          Text("Rabbit Rock") { Font(.serifs) }
            .backgroundColor(.red)
        }
      }

      """

    var configuration = Configuration.forTesting
    configuration.lineBreakAroundMultilineExpressionChainComponents = true
    assertPrettyPrintEqual(
      input: input,
      expected: expectedWithForcedBreaks,
      linelength: 50,
      configuration: configuration
    )
  }

  func testChainedTrailingClosureMethods() {
    let input =
      """
        var button =  View.Button { Text("ABC") }.action { presentAction() }.background(.red).text(.blue).text(.red).font(.appleSans)
        var button =  View.Button {
          // comment #0
          Text("ABC")
        }.action { presentAction() }.background(.red).text(.blue).text(.red).font(.appleSans)
        var button =  View.Button { Text("ABC") }
          .action { presentAction() }.background(.red).text(.blue) .text(.red).font(.appleSans)
        var button =  View.Button { Text("ABC") }
          .action {
            // comment #1
            presentAction()  // comment #2
          }.background(.red).text(.blue) .text(.red).font(.appleSans) /* trailing comment */
      var button =  View.Button { Text("ABC") }.action { presentAction() }.background(.red).text(.blue).text(.red).font(.appleSans).foo {
        abc in
        return abc.foo.bar
      }
      """

    let expectedNoForcedBreaks =
      """
      var button = View.Button { Text("ABC") }.action {
        presentAction()
      }.background(.red).text(.blue).text(.red).font(
        .appleSans)
      var button = View.Button {
        // comment #0
        Text("ABC")
      }.action { presentAction() }.background(.red)
        .text(.blue).text(.red).font(.appleSans)
      var button = View.Button { Text("ABC") }
        .action { presentAction() }.background(.red)
        .text(.blue).text(.red).font(.appleSans)
      var button = View.Button { Text("ABC") }
        .action {
          // comment #1
          presentAction()  // comment #2
        }.background(.red).text(.blue).text(.red).font(
          .appleSans) /* trailing comment */
      var button = View.Button { Text("ABC") }.action {
        presentAction()
      }.background(.red).text(.blue).text(.red).font(
        .appleSans
      ).foo {
        abc in
        return abc.foo.bar
      }

      """

    assertPrettyPrintEqual(input: input, expected: expectedNoForcedBreaks, linelength: 50)

    let expectedWithForcedBreaks =
      """
      var button = View.Button { Text("ABC") }
        .action { presentAction() }.background(.red)
        .text(.blue).text(.red).font(.appleSans)
      var button =
        View.Button {
          // comment #0
          Text("ABC")
        }
        .action { presentAction() }.background(.red)
        .text(.blue).text(.red).font(.appleSans)
      var button = View.Button { Text("ABC") }
        .action { presentAction() }.background(.red)
        .text(.blue).text(.red).font(.appleSans)
      var button = View.Button { Text("ABC") }
        .action {
          // comment #1
          presentAction()  // comment #2
        }
        .background(.red).text(.blue).text(.red)
        .font(.appleSans) /* trailing comment */
      var button = View.Button { Text("ABC") }
        .action { presentAction() }.background(.red)
        .text(.blue).text(.red).font(.appleSans)
        .foo {
          abc in
          return abc.foo.bar
        }

      """

    var configuration = Configuration.forTesting
    configuration.lineBreakAroundMultilineExpressionChainComponents = true
    assertPrettyPrintEqual(
      input: input,
      expected: expectedWithForcedBreaks,
      linelength: 50,
      configuration: configuration
    )
  }

  func testChainedSubscriptExprs() {
    let input =
      """
      var button =  View.Button[5, 4, 3] { Text("ABC") }.action { presentAction() }.background(.red).text(.blue).text(.red).font(.appleSans)
      var button =  View.Button[5,
        4, 3] { Text("ABC") }.action { presentAction() }.background(.red).text(.blue).text(.red).font(.appleSans)
      var button =  View.Button[5, 4, 3
      ] {
        // comment #0
        Text("ABC")
      }.action {
        // comment #1
        presentAction() }.background(.red).text(.blue).text(.red).font(.appleSans) /* trailing comment */
      var button =  View.Button[5, 4, 3] {
        Text("ABC")
      }.action { presentAction() }.background(.red).text(.blue).text(.red).font(.appleSans)[5]
      """

    let expectedNoForcedBreaks =
      """
      var button = View.Button[5, 4, 3] { Text("ABC") }
        .action { presentAction() }.background(.red)
        .text(.blue).text(.red).font(.appleSans)
      var button = View.Button[
        5,
        4, 3
      ] { Text("ABC") }.action { presentAction() }
        .background(.red).text(.blue).text(.red).font(
          .appleSans)
      var button = View.Button[
        5, 4, 3
      ] {
        // comment #0
        Text("ABC")
      }.action {
        // comment #1
        presentAction()
      }.background(.red).text(.blue).text(.red).font(
        .appleSans) /* trailing comment */
      var button = View.Button[5, 4, 3] {
        Text("ABC")
      }.action { presentAction() }.background(.red)
        .text(.blue).text(.red).font(.appleSans)[5]

      """

    assertPrettyPrintEqual(input: input, expected: expectedNoForcedBreaks, linelength: 50)

    let expectedWithForcedBreaks =
      """
      var button = View.Button[5, 4, 3] { Text("ABC") }
        .action { presentAction() }.background(.red)
        .text(.blue).text(.red).font(.appleSans)
      var button =
        View.Button[
          5,
          4, 3
        ] { Text("ABC") }
        .action { presentAction() }.background(.red)
        .text(.blue).text(.red).font(.appleSans)
      var button =
        View.Button[
          5, 4, 3
        ] {
          // comment #0
          Text("ABC")
        }
        .action {
          // comment #1
          presentAction()
        }
        .background(.red).text(.blue).text(.red)
        .font(.appleSans) /* trailing comment */
      var button =
        View.Button[5, 4, 3] {
          Text("ABC")
        }
        .action { presentAction() }.background(.red)
        .text(.blue).text(.red).font(.appleSans)[5]

      """

    var configuration = Configuration.forTesting
    configuration.lineBreakAroundMultilineExpressionChainComponents = true
    assertPrettyPrintEqual(
      input: input,
      expected: expectedWithForcedBreaks,
      linelength: 50,
      configuration: configuration
    )
  }
}

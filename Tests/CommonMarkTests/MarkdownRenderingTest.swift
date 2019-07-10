import CommonMark
import XCTest

final class MarkdownRedneringTest: XCTestCase {

  func testStringRenderedUsing_blockQuote() {
    let document = MarkdownDocument(
      children: [
        BlockQuoteNode(children: [
          ParagraphNode(children: [
            TextNode(literalContent: "Some text.")
          ]),
        ]),
      ])
    let rendered = document.string(renderedUsing: .commonMark)
    XCTAssertEqual(rendered, """
      > Some text.

      """)
  }

  func testStringRenderedUsing_codeBlock() {
    let document = MarkdownDocument(
      children: [
        CodeBlockNode(
          literalContent: """
            func foo() {
              bar()
            }
            """,
          fenceText: "swift")
      ])
    let rendered = document.string(renderedUsing: .commonMark)
    XCTAssertEqual(rendered, """
      ``` swift
      func foo() {
        bar()
      }
      ```

      """)
  }

  func testStringRenderedUsing_emphasis() {
    let document = MarkdownDocument(
      children: [
        ParagraphNode(children: [
          EmphasisNode(children: [
            TextNode(literalContent: "Some text."),
          ]),
        ]),
      ])
    let rendered = document.string(renderedUsing: .commonMark)
    XCTAssertEqual(rendered, """
      *Some text.*

      """)
  }

  func testStringRenderedUsing_heading() {
    let document = MarkdownDocument(
      children: [
        HeadingNode(level: .h1, children: [TextNode(literalContent: "header 1")]),
        HeadingNode(level: .h2, children: [TextNode(literalContent: "header 2")]),
        HeadingNode(level: .h3, children: [TextNode(literalContent: "header 3")]),
        HeadingNode(level: .h4, children: [TextNode(literalContent: "header 4")]),
        HeadingNode(level: .h5, children: [TextNode(literalContent: "header 5")]),
        HeadingNode(level: .h6, children: [TextNode(literalContent: "header 6")]),
      ])
    let rendered = document.string(renderedUsing: .commonMark)
    XCTAssertEqual(rendered, """
      # header 1

      ## header 2

      ### header 3

      #### header 4

      ##### header 5

      ###### header 6

      """)
  }

  func testStringRenderedUsing_htmlBlock() {
    let document = MarkdownDocument(
      children: [
        HTMLBlockNode(literalContent: "<p>Raw HTML.</p>"),
      ])
    let rendered = document.string(renderedUsing: .commonMark)
    XCTAssertEqual(rendered, """
      <p>Raw HTML.</p>

      """)
  }

  func testStringRenderedUsing_image() {
    let document = MarkdownDocument(
      children: [
        ParagraphNode(children: [
          ImageNode(
            url: URL(string: "http://foo.bar")!,
            title: "foo bar",
            children: [TextNode(literalContent: "image text")]
          ),
        ]),
      ])
    let rendered = document.string(renderedUsing: .commonMark)
    XCTAssertEqual(rendered, """
      ![image text](http://foo.bar "foo bar")

      """)
  }

  func testStringRenderedUsing_inlineCode() {
    let document = MarkdownDocument(
      children: [
        ParagraphNode(children: [
          TextNode(literalContent: "Some "),
          InlineCodeNode(literalContent: "code"),
          TextNode(literalContent: " text."),
        ]),
      ])
    let rendered = document.string(renderedUsing: .commonMark)
    XCTAssertEqual(rendered, """
      Some `code` text.

      """)
  }

  func testStringRenderedUsing_inlineHTML() {
    let document = MarkdownDocument(
      children: [
        ParagraphNode(children: [
          TextNode(literalContent: "Some "),
          InlineHTMLNode(literalContent: "<b>"),
          TextNode(literalContent: "bold"),
          InlineHTMLNode(literalContent: "</b>"),
          TextNode(literalContent: " text."),
        ]),
      ])
    let rendered = document.string(renderedUsing: .commonMark)
    XCTAssertEqual(rendered, """
      Some <b>bold</b> text.

      """)
  }

  func testStringRenderedUsing_lineBreak() {
    let document = MarkdownDocument(
      children: [
        ParagraphNode(children: [
          TextNode(literalContent: "Before the break."),
          LineBreakNode(),
          TextNode(literalContent: "After the break."),
        ]),
      ])
    let rendered = document.string(renderedUsing: .commonMark)
    XCTAssertEqual(rendered, """
      Before the break.\u{0020}\u{0020}
      After the break.

      """)
  }

  func testStringRenderedUsing_link() {
    let document = MarkdownDocument(
      children: [
        ParagraphNode(children: [
          LinkNode(
            url: URL(string: "http://foo.bar")!,
            title: "foo bar",
            children: [TextNode(literalContent: "link text")]),
        ]),
      ])
    let rendered = document.string(renderedUsing: .commonMark)
    XCTAssertEqual(rendered, """
      [link text](http://foo.bar "foo bar")

      """)
  }

  func testStringRenderedUsing_listBulleted() {
    let document = MarkdownDocument(
      children: [
        ListNode(
          listType: .bulleted,
          items: [
            ListItemNode(children: [ParagraphNode(children: [TextNode(literalContent: "item 1")])]),
            ListItemNode(children: [ParagraphNode(children: [TextNode(literalContent: "item 2")])]),
            ListItemNode(children: [ParagraphNode(children: [TextNode(literalContent: "item 3")])]),
          ],
          isTight: true
        ),
      ])
    let rendered = document.string(renderedUsing: .commonMark)
    XCTAssertEqual(rendered, """
        - item 1
        - item 2
        - item 3

      """)
  }

  func testStringRenderedUsing_listOrdered() {
    let document = MarkdownDocument(
      children: [
        ListNode(
          listType: .ordered(delimiter: .parenthesis, startingNumber: 10),
          items: [
            ListItemNode(children: [ParagraphNode(children: [TextNode(literalContent: "item 1")])]),
            ListItemNode(children: [ParagraphNode(children: [TextNode(literalContent: "item 2")])]),
            ListItemNode(children: [ParagraphNode(children: [TextNode(literalContent: "item 3")])]),
          ],
          isTight: true
        ),
      ])
    let rendered = document.string(renderedUsing: .commonMark)
    XCTAssertEqual(rendered, """
      10) item 1
      11) item 2
      12) item 3

      """)
  }

  func testStringRenderedUsing_paragraph() {
    let document = MarkdownDocument(
      children: [
        ParagraphNode(children: [TextNode(literalContent: "First paragraph.")]),
        ParagraphNode(children: [TextNode(literalContent: "Second paragraph.")]),
      ])
    let rendered = document.string(renderedUsing: .commonMark)
    XCTAssertEqual(rendered, """
      First paragraph.

      Second paragraph.

      """)
  }

  func testStringRenderedUsing_softBreak() {
    let document = MarkdownDocument(
      children: [
        ParagraphNode(children: [
          TextNode(literalContent: "Before the break."),
          SoftBreakNode(),
          TextNode(literalContent: "After the break."),
        ]),
      ])
    let rendered = document.string(renderedUsing: .commonMark(width: 0))
    XCTAssertEqual(rendered, """
      Before the break.
      After the break.

      """)
  }

  func testStringRenderedUsing_strong() {
    let document = MarkdownDocument(
      children: [
        ParagraphNode(children: [
          StrongNode(children: [
            TextNode(literalContent: "Some text."),
          ]),
        ]),
      ])
    let rendered = document.string(renderedUsing: .commonMark)
    XCTAssertEqual(rendered, """
      **Some text.**

      """)
  }

  func testStringRenderedUsing_text() {
    let document = MarkdownDocument(
      children: [
        ParagraphNode(children: [TextNode(literalContent: "Some text.")]),
      ])
    let rendered = document.string(renderedUsing: .commonMark)
    XCTAssertEqual(rendered, """
      Some text.

      """)
  }

  func testStringRenderedUsing_thematicBreak() {
    let document = MarkdownDocument(
      children: [
        ParagraphNode(children: [TextNode(literalContent: "First paragraph.")]),
        ThematicBreakNode(),
        ParagraphNode(children: [TextNode(literalContent: "Second paragraph.")]),
      ])
    let rendered = document.string(renderedUsing: .commonMark)
    XCTAssertEqual(rendered, """
      First paragraph.

      -----

      Second paragraph.

      """)
  }
}

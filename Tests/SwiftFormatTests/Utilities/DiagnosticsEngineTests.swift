import XCTest

@testable import swift_format

final class DiagnosticsEngineTests: XCTestCase {

  func noOpHandler(diag: Diagnostic) -> Void {
  }

  func testHasErrors() throws {
    let engine = DiagnosticsEngine(diagnosticsHandlers: [noOpHandler])
    XCTAssertFalse(engine.hasErrors)

    engine.emitError("")
    XCTAssertTrue(engine.hasErrors)
  }
}

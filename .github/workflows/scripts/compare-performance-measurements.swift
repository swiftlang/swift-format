import Foundation

func printToStderr(_ value: String) {
  fputs(value, stderr)
}

func extractMeasurements(output: String) -> [String: Double] {
  var measurements: [String: Double] = [:]
  for line in output.split(separator: "\n") {
    guard let colonPosition = line.lastIndex(of: ":") else {
      printToStderr("Ignoring following measurement line because it doesn't contain a colon: \(line)")
      continue
    }
    let beforeColon = String(line[..<colonPosition]).trimmingCharacters(in: .whitespacesAndNewlines)
    let afterColon = String(line[line.index(after: colonPosition)...]).trimmingCharacters(
      in: .whitespacesAndNewlines
    )
    guard let value = Double(afterColon) else {
      printToStderr("Ignoring following measurement line because the value can't be parsed as a Double: \(line)")
      continue
    }
    measurements[beforeColon] = value
  }
  return measurements
}

extension Double {
  func round(toDecimalDigits decimalDigits: Int) -> Double {
    return (self * pow(10, Double(decimalDigits))).rounded() / pow(10, Double(decimalDigits))
  }
}

func run(
  baselinePerformanceOutput: String,
  changedPerformanceOutput: String,
  sensitivityPercentage: Double
) -> (output: String, hasDetectedSignificantChange: Bool) {
  let baselineMeasurements = extractMeasurements(output: baselinePerformanceOutput)
  let changedMeasurements = extractMeasurements(output: changedPerformanceOutput)

  var hasDetectedSignificantChange = false
  var output = ""
  for (measurementName, baselineValue) in baselineMeasurements.sorted(by: { $0.key < $1.key }) {
    guard let changedValue = changedMeasurements[measurementName] else {
      output += "🛑 \(measurementName) not present after changes\n"
      continue
    }
    let differencePercentage = (changedValue - baselineValue) / baselineValue * 100
    let rawMeasurementsText = "(baseline: \(baselineValue), after changes: \(changedValue))"
    if differencePercentage < -sensitivityPercentage {
      output +=
        "🎉 \(measurementName) improved by \(-differencePercentage.round(toDecimalDigits: 3))% \(rawMeasurementsText)\n"
      hasDetectedSignificantChange = true
    } else if differencePercentage > sensitivityPercentage {
      output +=
        "⚠️ \(measurementName) regressed by \(differencePercentage.round(toDecimalDigits: 3))% \(rawMeasurementsText)\n"
      hasDetectedSignificantChange = true
    } else {
      output +=
        "➡️ \(measurementName) did not change significantly with \(differencePercentage.round(toDecimalDigits: 3))% \(rawMeasurementsText)\n"
    }
  }
  return (output, hasDetectedSignificantChange)
}

guard CommandLine.arguments.count > 2 else {
  print("Expected at least two parameters: The baseline performance output and the changed performance output")
  exit(1)
}

let baselinePerformanceOutput = CommandLine.arguments[1]
let changedPerformanceOutput = CommandLine.arguments[2]

let sensitivityPercentage =
  if CommandLine.arguments.count > 3, let percentage = Double(CommandLine.arguments[3]) {
    percentage
  } else {
    1.0 /* percent */
  }

let (output, hasDetectedSignificantChange) = run(
  baselinePerformanceOutput: baselinePerformanceOutput,
  changedPerformanceOutput: changedPerformanceOutput,
  sensitivityPercentage: sensitivityPercentage
)

print(output)
if hasDetectedSignificantChange {
  exit(1)
}

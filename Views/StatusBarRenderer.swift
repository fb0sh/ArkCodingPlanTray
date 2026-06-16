import AppKit

/// Renders a status bar icon with a black filled circle + purple solid arc.
final class StatusBarRenderer {
    // MARK: - Properties

    private let circleRadius: CGFloat = 7
    private let arcWidth: CGFloat = 5
    private let textFontSize: CGFloat = 11
    private let padding: CGFloat = 4

    // MARK: - Image Generation

    func renderImage(percent: Double) -> NSImage {
        let text = formattedText(percent)
        let textSize = textSize(for: text)
        let circleDiameter = circleRadius * 2
        let totalWidth = padding + circleDiameter + 3 + textSize.width + padding
        let height: CGFloat = 22

        let image = NSImage(size: NSSize(width: totalWidth, height: height))
        image.isTemplate = false

        image.lockFocus()
        defer { image.unlockFocus() }

        guard let ctx = NSGraphicsContext.current?.cgContext else { return image }

        let circleY = (height - circleDiameter) / 2
        let circleRect = CGRect(
            x: padding,
            y: circleY,
            width: circleDiameter,
            height: circleDiameter
        )

        // Background circle — RGB(129, 135, 141)
        ctx.setFillColor(CGColor(red: 129/255, green: 135/255, blue: 141/255, alpha: 1.0))
        ctx.fillEllipse(in: circleRect)

        // Progress pie slice — RGB(231, 233, 234)
        let clampedPercent = min(max(percent / 100.0, 0), 1.0)
        if clampedPercent > 0 {
            let startAngle: CGFloat = -.pi / 2
            let endAngle = startAngle + CGFloat(clampedPercent) * 2 * .pi

            let center = CGPoint(x: circleRect.midX, y: circleRect.midY)
            let path = CGMutablePath()
            path.move(to: center)
            path.addArc(center: center,
                        radius: circleRadius,
                        startAngle: startAngle,
                        endAngle: endAngle,
                        clockwise: false)
            path.closeSubpath()

            ctx.setFillColor(CGColor(red: 82/255, green: 82/255, blue: 225/255, alpha: 1.0))
            ctx.addPath(path)
            ctx.fillPath()
        }

        // Text
        let textX = circleRect.maxX + 3
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: textFontSize, weight: .medium),
            .foregroundColor: NSColor.white
        ]

        let attributed = NSAttributedString(string: text, attributes: attrs)
        let textY = (height - textSize.height) / 2
        attributed.draw(at: NSPoint(x: textX, y: textY))

        return image
    }

    func renderFallbackImage() -> NSImage {
        let image = NSImage(systemSymbolName: "chart.pie.fill", accessibilityDescription: "ArkCodingPlanTray")!
        image.isTemplate = true
        return image
    }

    // MARK: - Helpers

    private func formattedText(_ percent: Double) -> String {
        if percent >= 100 {
            return "100%"
        } else if percent >= 10 {
            return String(format: "%.0f%%", percent)
        } else {
            return String(format: "%.1f%%", percent)
        }
    }

    private func textSize(for text: String) -> NSSize {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: textFontSize, weight: .medium)
        ]
        return NSAttributedString(string: text, attributes: attrs).size()
    }
}

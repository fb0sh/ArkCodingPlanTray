import SwiftUI

// MARK: - PopoverContentView

struct PopoverContentView: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)

            Divider()
                .padding(.horizontal, 8)

            // Content
            contentArea

            Divider()
                .padding(.horizontal, 8)

            // Bottom Toolbar
            bottomToolbar
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
        }
        .frame(width: 420)
        .background(
            VisualEffectView(material: .popover, blendingMode: .behindWindow)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(red: 82/255, green: 82/255, blue: 225/255))

                Text("ArkCodingPlanTray")
                    .font(.system(size: 13, weight: .semibold))
            }

            Spacer()

            if let lastRefreshed = viewModel.lastRefreshedAt {
                Text(formatRelative(lastRefreshed))
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: - Content Area

    @ViewBuilder
    private var contentArea: some View {
        if viewModel.isLoading && viewModel.usage == nil {
            loadingView
        } else if let error = viewModel.errorMessage {
            errorView(message: error)
        } else if let usage = viewModel.usage {
            if viewModel.layoutMode == .vertical {
                verticalUsageView(usage: usage)
            } else {
                horizontalUsageView(usage: usage)
            }
        } else {
            emptyView
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 12) {
            Spacer().frame(height: 30)
            ProgressView()
                .scaleEffect(0.8)
                .controlSize(.small)
            Text("Loading usage data...")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            Spacer().frame(height: 30)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Error

    private func errorView(message: String) -> some View {
        VStack(spacing: 12) {
            Spacer().frame(height: 30)

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 24))
                .foregroundColor(.orange)

            Text("Failed to load data")
                .font(.system(size: 13, weight: .medium))

            Text(message)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button {
                viewModel.refresh()
            } label: {
                Text("Retry")
                    .font(.system(size: 12, weight: .medium))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)

            Spacer().frame(height: 30)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Empty

    private var emptyView: some View {
        VStack(spacing: 8) {
            Spacer().frame(height: 40)

            Image(systemName: "chart.pie")
                .font(.system(size: 28))
                .foregroundColor(.secondary.opacity(0.5))

            Text("No usage data")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)

            Spacer().frame(height: 40)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Vertical Layout (circles)

    private func verticalUsageView(usage: CodingPlanUsage) -> some View {
        VStack(spacing: 12) {
            statusBadge(status: usage.status)

            HStack(spacing: 16) {
                ForEach(usage.quotaUsage) { quota in
                    CircleQuotaView(quota: quota)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 4)
        }
        .padding(.vertical, 12)
    }

    // MARK: - Horizontal Layout (bars)

    private func horizontalUsageView(usage: CodingPlanUsage) -> some View {
        VStack(spacing: 10) {
            statusBadge(status: usage.status)

            VStack(spacing: 6) {
                ForEach(usage.quotaUsage) { quota in
                    BarQuotaView(quota: quota)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 4)
        }
        .padding(.vertical, 12)
    }

    private func statusBadge(status: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor(status))
                .frame(width: 8, height: 8)

            Text(status)
                .font(.system(size: 12, weight: .medium))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(statusColor(status).opacity(0.1))
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
    }

    private func statusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "running": return Color(red: 82/255, green: 82/255, blue: 225/255)
        case "paused": return .orange
        case "stopped": return .red
        default: return .gray
        }
    }

    // MARK: - Bottom Toolbar

    private var bottomToolbar: some View {
        HStack(spacing: 0) {
            // Refresh
            toolbarButton(
                icon: "arrow.clockwise",
                shortcut: "⌘R",
                action: { viewModel.refresh() }
            )

            Spacer()

            // Toggle layout
            Button {
                viewModel.toggleLayout()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: viewModel.layoutMode == .vertical
                          ? "chart.bar.fill"
                          : "circle.grid.2x2.fill")
                        .font(.system(size: 11))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(Color.primary.opacity(0.06))
                )
            }
            .buttonStyle(.plain)
            .help(viewModel.layoutMode == .vertical ? "Switch to bars" : "Switch to circles")

            Spacer()

            // Open ArkCodingPlanTray
            toolbarButton(
                icon: "arrow.up.forward.app",
                shortcut: nil,
                action: { viewModel.openArkCodingPlanTray() }
            )

            Spacer()

            // Settings
            toolbarButton(
                icon: "gearshape",
                shortcut: nil,
                action: { openSettings() }
            )

            Spacer()

            // Quit
            toolbarButton(
                icon: "power",
                shortcut: "⌘Q",
                action: { NSApp.terminate(nil) }
            )
        }
    }

    private func toolbarButton(icon: String, shortcut: String?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                if let shortcut = shortcut {
                    Text(shortcut)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(Color.primary.opacity(0.06))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func formatRelative(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func openSettings() {
        NotificationCenter.default.post(name: NSNotification.Name("ClosePopover"), object: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            NotificationCenter.default.post(name: NSNotification.Name("OpenSettings"), object: nil)
        }
    }
}

// MARK: - CircleQuotaView

struct CircleQuotaView: View {
    let quota: QuotaUsage

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.08), lineWidth: 6)
                    .frame(width: 60, height: 60)

                Circle()
                    .trim(from: 0, to: CGFloat(min(quota.percent / 100.0, 1.0)))
                    .stroke(percentColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: quota.percent)

                Text(String(format: "%.0f%%", quota.percent))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(percentColor)
            }

            Text(quota.displayName)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)

            Text("Resets \(formatResetDate(quota.resetDate))")
                .font(.system(size: 8))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private var percentColor: Color {
        return Color(red: 82/255, green: 82/255, blue: 225/255)
    }

    private func formatResetDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - BarQuotaView

struct BarQuotaView: View {
    let quota: QuotaUsage

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(quota.displayName)
                    .font(.system(size: 11, weight: .medium))

                Spacer()

                Text(String(format: "%.1f%%", quota.percent))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(percentColor)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.primary.opacity(0.08))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(percentColor)
                        .frame(width: geometry.size.width * CGFloat(min(quota.percent / 100.0, 1.0)), height: 8)
                }
            }
            .frame(height: 8)

            HStack {
                Spacer()
                Text("Resets \(formatResetDate(quota.resetDate))")
                    .font(.system(size: 8))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
    }

    private var percentColor: Color {
        return Color(red: 82/255, green: 82/255, blue: 225/255)
    }

    private func formatResetDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - VisualEffectView

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        view.wantsLayer = true
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

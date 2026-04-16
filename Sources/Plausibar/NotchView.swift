import SwiftUI

struct NotchView: View {
    @EnvironmentObject var store: StatsStore
    @Environment(\.openSettings) private var openSettings
    @State private var expanded = false

    let notchWidth: CGFloat
    let notchHeight: CGFloat
    let sidePadding: CGFloat = 56
    private let notchGap: CGFloat = 8

    private var shapeHeight: CGFloat {
        expanded ? notchHeight + 180 : notchHeight
    }

    private var contentWidth: CGFloat {
        notchWidth + sidePadding * 2
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                NotchShape(
                    notchWidth: notchWidth,
                    notchHeight: notchHeight,
                    bottomCornerRadius: expanded ? 16 : 8
                )
                .fill(Color.black)
                .frame(width: contentWidth, height: shapeHeight)
                .shadow(color: .black.opacity(expanded ? 0.35 : 0), radius: 18, y: 6)

                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        HStack {
                            Spacer(minLength: 0)
                            leftItem.padding(.trailing, notchGap)
                        }
                        .frame(width: sidePadding, height: notchHeight)

                        Color.clear.frame(width: notchWidth, height: notchHeight)

                        HStack {
                            rightItem.padding(.leading, notchGap)
                            Spacer(minLength: 0)
                        }
                        .frame(width: sidePadding, height: notchHeight)
                    }

                    if expanded {
                        expandedPanel
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            .padding(.bottom, 14)
                            .transition(.asymmetric(
                                insertion: .opacity.animation(.easeIn(duration: 0.15).delay(0.12)),
                                removal: .opacity.animation(.easeOut(duration: 0.08))
                            ))
                    }
                }
                .frame(width: contentWidth)
                .foregroundStyle(.white)
            }
            .frame(width: contentWidth, height: shapeHeight)
            .contentShape(
                NotchShape(
                    notchWidth: notchWidth,
                    notchHeight: notchHeight,
                    bottomCornerRadius: expanded ? 16 : 8
                )
            )
            .animation(.spring(response: 0.4, dampingFraction: 0.82), value: expanded)
            .onHover { hovering in expanded = hovering }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var leftItem: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(liveColor)
                .frame(width: 6, height: 6)
            Text(store.realtime.map(compact) ?? "–")
                .monospacedDigit()
                .font(.system(size: 12, weight: .semibold))
        }
    }

    private var rightItem: some View {
        HStack(spacing: 4) {
            Text(store.todayPageviews.map(compact) ?? "–")
                .monospacedDigit()
                .font(.system(size: 12, weight: .semibold))
            Image(systemName: "eye.fill")
                .font(.system(size: 9))
                .foregroundStyle(.white.opacity(0.65))
        }
    }

    private var liveColor: Color {
        guard let rt = store.realtime else { return .gray }
        return rt > 0 ? .green : .white.opacity(0.35)
    }

    private var expandedPanel: some View {
        VStack(alignment: .leading, spacing: 7) {
            if let err = store.errorMessage {
                Text(err)
                    .font(.system(size: 10))
                    .foregroundStyle(.red.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                statRow("Right now", store.realtime.map { "\($0)" } ?? "–")
                statRow("Visitors today", store.todayVisitors.map(compact) ?? "–")
                statRow("Pageviews today", store.todayPageviews.map(compact) ?? "–")
                if let br = store.bounceRate {
                    statRow("Bounce rate", "\(Int(br))%")
                }
                if let vd = store.visitDuration {
                    statRow("Visit duration", formatDuration(vd))
                }
            }
            HStack(spacing: 10) {
                if let u = store.lastUpdated {
                    Text(u.formatted(date: .omitted, time: .standard))
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.4))
                }
                Spacer()
                iconButton("arrow.clockwise", help: "Refresh") {
                    Task { await store.refresh() }
                }
                iconButton("gearshape", help: "Settings") {
                    NSApp.activate(ignoringOtherApps: true)
                    openSettings()
                }
                iconButton("power", help: "Quit Plausibar") {
                    NSApp.terminate(nil)
                }
            }
            .padding(.top, 2)
        }
        .font(.system(size: 11))
    }

    private func iconButton(_ systemName: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.7))
        }
        .buttonStyle(.plain)
        .help(help)
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.white.opacity(0.65))
            Spacer()
            Text(value).monospacedDigit().bold()
        }
    }

    private func compact(_ n: Int) -> String {
        if n >= 10_000 {
            return String(format: "%.0fk", Double(n) / 1000)
        }
        if n >= 1_000 {
            return String(format: "%.1fk", Double(n) / 1000)
        }
        return "\(n)"
    }

    private func formatDuration(_ s: Double) -> String {
        let sec = Int(s)
        return String(format: "%d:%02d", sec / 60, sec % 60)
    }
}

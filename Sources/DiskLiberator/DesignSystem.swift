import SwiftUI

// MARK: - Design Tokens
enum ColorToken {
    static let sidebar = Color(red: 0.11, green: 0.11, blue: 0.12)
    static let card = Color(red: 0.15, green: 0.15, blue: 0.16)
    static let bg = Color(red: 0.06, green: 0.06, blue: 0.07)
    static let primary = Color.white
    static let secondary = Color(white: 0.55)
    static let blue = Color(red: 0.0, green: 0.48, blue: 1.0)
    static let orange = Color(red: 1.0, green: 0.58, blue: 0.0)
    static let green = Color(red: 0.18, green: 0.8, blue: 0.44)
    static let red = Color(red: 1.0, green: 0.23, blue: 0.19)
    static let teal = Color(red: 0.35, green: 0.78, blue: 0.98)
    static let purple = Color(red: 0.69, green: 0.32, blue: 1.0)
}

extension LinearGradient {
    static func accent(_ color: Color) -> LinearGradient {
        LinearGradient(colors: [color.opacity(0.85), color], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Sidebar
struct SidebarButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon).font(.system(size: 16, weight: .medium)).frame(width: 22)
                Text(label).font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                Spacer()
            }
            .foregroundStyle(isSelected ? Color.blue : ColorToken.secondary)
            .padding(.horizontal, 12).padding(.vertical, 10)
            .background(isSelected ? Color.blue.opacity(0.12) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Feature Card
struct FeatureCard<Content: View>: View {
    let icon: String
    let title: String
    let color: Color
    var badge: String? = nil
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10).fill(LinearGradient.accent(color)).frame(width: 34, height: 34)
                    Image(systemName: icon).font(.system(size: 15, weight: .semibold)).foregroundStyle(.white)
                }
                Text(title).font(.system(size: 15, weight: .semibold)).foregroundStyle(ColorToken.primary)
                Spacer()
                if let b = badge {
                    Text(b).font(.system(size: 11, weight: .bold, design: .monospaced)).foregroundStyle(color)
                        .padding(.horizontal, 8).padding(.vertical, 3).background(color.opacity(0.15)).clipShape(Capsule())
                }
            }
            content
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 14).fill(ColorToken.card))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.05), lineWidth: 1))
    }
}

// MARK: - Buttons
struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    var disabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 12, weight: .bold))
                Text(title).font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 14).padding(.vertical, 7)
            .background(RoundedRectangle(cornerRadius: 7).fill(
                disabled ? color.opacity(0.25) : color
            ))
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }
}

// MARK: - Meter
struct LargeMeter: View {
    let value: Double
    let color: Color
    let label: String
    let detail: String

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle().stroke(color.opacity(0.12), lineWidth: 8)
                Circle().trim(from: 0, to: value)
                    .stroke(color.gradient, style: .init(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 1), value: value)
                VStack(spacing: 0) {
                    Text("\(Int(value * 100))").font(.system(size: 28, weight: .bold, design: .monospaced)).foregroundStyle(ColorToken.primary)
                    Text("%").font(.system(size: 11, weight: .medium)).foregroundStyle(ColorToken.secondary)
                }
            }
            .frame(width: 90, height: 90)
            Text(label).font(.system(size: 12, weight: .medium)).foregroundStyle(ColorToken.secondary)
            Text(detail).font(.system(size: 11, design: .monospaced)).foregroundStyle(color)
        }
    }
}

// MARK: - Progress
struct ProgressBarView: View {
    let value: Double
    let color: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4).fill(color.opacity(0.12)).frame(height: 8)
                RoundedRectangle(cornerRadius: 4)
                    .fill(color.gradient)
                    .frame(width: max(geo.size.width * value, 2), height: 8)
                    .animation(.easeOut(duration: 0.3), value: value)
            }
        }
        .frame(height: 8)
    }
}

struct ProgressCardView: View {
    let title: String
    let progress: Double
    let color: Color
    let status: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title).font(.system(size: 13, weight: .medium)).foregroundStyle(ColorToken.primary)
                Spacer()
                Text(status).font(.system(size: 11)).foregroundStyle(ColorToken.secondary)
            }
            ProgressBarView(value: progress, color: color)
        }
        .padding(14).background(RoundedRectangle(cornerRadius: 10).fill(ColorToken.card))
    }
}

// MARK: - Mini Button
struct MiniButton: View {
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon).font(.system(size: 11, weight: .bold)).foregroundStyle(color)
                .padding(6).background(color.opacity(0.12)).clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Stats
struct StatRowView: View {
    let label: String
    let value: String
    var color: Color = ColorToken.secondary

    var body: some View {
        HStack {
            Text(label).font(.system(size: 13)).foregroundStyle(ColorToken.secondary)
            Spacer()
            Text(value).font(.system(size: 13, weight: .medium, design: .monospaced)).foregroundStyle(color)
        }
    }
}

// MARK: - Extensions
extension ByteCountFormatter {
    static func short(_ bytes: Int64) -> String {
        string(fromByteCount: bytes, countStyle: .memory)
    }
}

extension FileManager {
    var home: URL { homeDirectoryForCurrentUser }
}

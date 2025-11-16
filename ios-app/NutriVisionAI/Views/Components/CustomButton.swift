//
//  CustomButton.swift
//  NutriVision AI
//
//  Reusable custom button component
//

import SwiftUI

struct CustomButton: View {
    let title: String
    let icon: String?
    let style: ButtonStyle
    let isLoading: Bool
    let action: () -> Void

    enum ButtonStyle {
        case primary
        case secondary
        case destructive
        case outline

        var backgroundColor: Color {
            switch self {
            case .primary:
                return .green
            case .secondary:
                return .blue
            case .destructive:
                return .red
            case .outline:
                return .clear
            }
        }

        var foregroundColor: Color {
            switch self {
            case .primary, .secondary, .destructive:
                return .white
            case .outline:
                return .green
            }
        }

        var borderColor: Color? {
            switch self {
            case .outline:
                return .green
            default:
                return nil
            }
        }
    }

    init(
        title: String,
        icon: String? = nil,
        style: ButtonStyle = .primary,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon, !isLoading {
                    Image(systemName: icon)
                }

                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: style.foregroundColor))
                } else {
                    Text(title)
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(style.backgroundColor)
            .foregroundColor(style.foregroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(style.borderColor ?? Color.clear, lineWidth: 2)
            )
        }
        .disabled(isLoading)
    }
}

// MARK: - Compact Button Variant

struct CompactButton: View {
    let title: String
    let icon: String?
    let color: Color
    let action: () -> Void

    init(
        title: String,
        icon: String? = nil,
        color: Color = .green,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.color = color
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .cornerRadius(8)
        }
    }
}

// MARK: - Icon Button

struct IconButton: View {
    let icon: String
    let color: Color
    let size: CGFloat
    let action: () -> Void

    init(
        icon: String,
        color: Color = .green,
        size: CGFloat = 44,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.color = color
        self.size = size
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.45))
                .foregroundColor(color)
                .frame(width: size, height: size)
                .background(color.opacity(0.1))
                .clipShape(Circle())
        }
    }
}

struct CustomButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            CustomButton(title: "Primary Button", icon: "checkmark", style: .primary) {
                print("Primary tapped")
            }

            CustomButton(title: "Secondary Button", icon: "star.fill", style: .secondary) {
                print("Secondary tapped")
            }

            CustomButton(title: "Destructive Button", icon: "trash", style: .destructive) {
                print("Destructive tapped")
            }

            CustomButton(title: "Outline Button", icon: "arrow.right", style: .outline) {
                print("Outline tapped")
            }

            CustomButton(title: "Loading...", style: .primary, isLoading: true) {
                print("Loading")
            }

            HStack {
                CompactButton(title: "Compact", icon: "plus") {
                    print("Compact tapped")
                }

                IconButton(icon: "heart.fill") {
                    print("Icon tapped")
                }
            }
        }
        .padding()
    }
}

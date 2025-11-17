//
//  DietaryBadge.swift
//  NutriVision AI
//
//  Reusable dietary restriction badge component
//

import SwiftUI

struct DietaryBadge: View {
    let text: String
    var color: Color = .blue
    var size: BadgeSize = .medium

    enum BadgeSize {
        case small, medium, large

        var fontSize: Font {
            switch self {
            case .small: return .caption2
            case .medium: return .caption
            case .large: return .subheadline
            }
        }

        var padding: EdgeInsets {
            switch self {
            case .small: return EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6)
            case .medium: return EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
            case .large: return EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
            }
        }
    }

    var body: some View {
        Text(text)
            .font(size.fontSize)
            .fontWeight(.semibold)
            .padding(size.padding)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(12)
    }

    // Convenience initializers for common dietary restrictions
    static func vegan(size: BadgeSize = .medium) -> some View {
        DietaryBadge(text: "Vegan", color: .green, size: size)
    }

    static func vegetarian(size: BadgeSize = .medium) -> some View {
        DietaryBadge(text: "Vegetarian", color: .green, size: size)
    }

    static func glutenFree(size: BadgeSize = .medium) -> some View {
        DietaryBadge(text: "Gluten-Free", color: .orange, size: size)
    }

    static func dairyFree(size: BadgeSize = .medium) -> some View {
        DietaryBadge(text: "Dairy-Free", color: .purple, size: size)
    }

    static func keto(size: BadgeSize = .medium) -> some View {
        DietaryBadge(text: "Keto", color: .red, size: size)
    }
}

struct DietaryBadge_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 8) {
            HStack {
                DietaryBadge.vegan()
                DietaryBadge.vegetarian()
                DietaryBadge.glutenFree()
            }
            HStack {
                DietaryBadge.dairyFree(size: .small)
                DietaryBadge.keto(size: .large)
            }
        }
        .padding()
    }
}

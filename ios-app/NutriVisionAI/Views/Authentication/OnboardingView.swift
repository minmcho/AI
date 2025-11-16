//
//  OnboardingView.swift
//  NutriVision AI
//
//  Onboarding and feature introduction view
//

import SwiftUI

struct OnboardingView: View {
    @Binding var showOnboarding: Bool
    @State private var currentPage = 0

    let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "camera.fill",
            title: "Scan Your Food",
            description: "Use AI-powered BLIP technology to instantly identify food items and get detailed nutritional information",
            color: .green
        ),
        OnboardingPage(
            icon: "brain.head.profile",
            title: "AI Nutrition Assistant",
            description: "Chat with our intelligent AI assistant powered by LLaMA to get personalized nutrition advice and recipe recommendations",
            color: .blue
        ),
        OnboardingPage(
            icon: "mic.fill",
            title: "Voice Commands",
            description: "Control the app hands-free with voice commands in 6 languages: English, Chinese, Japanese, Korean, Thai, and Myanmar",
            color: .purple
        ),
        OnboardingPage(
            icon: "calendar",
            title: "Smart Meal Planning",
            description: "Generate personalized meal plans based on your health goals, dietary preferences, and restrictions",
            color: .orange
        ),
        OnboardingPage(
            icon: "cart.fill",
            title: "Shopping Lists",
            description: "Automatically create shopping lists from your meal plans and track your grocery purchases",
            color: .pink
        )
    ]

    var body: some View {
        ZStack {
            // Page content
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    OnboardingPageView(page: pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

            // Custom page indicator and buttons
            VStack {
                Spacer()

                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? pages[currentPage].color : Color.gray.opacity(0.3))
                            .frame(width: 10, height: 10)
                            .scaleEffect(currentPage == index ? 1.2 : 1.0)
                            .animation(.spring(), value: currentPage)
                    }
                }
                .padding(.bottom, 20)

                // Action buttons
                HStack {
                    if currentPage > 0 {
                        Button("Previous") {
                            withAnimation {
                                currentPage -= 1
                            }
                        }
                        .foregroundColor(.gray)
                    }

                    Spacer()

                    if currentPage < pages.count - 1 {
                        Button(action: {
                            withAnimation {
                                currentPage += 1
                            }
                        }) {
                            Text("Next")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 12)
                                .background(pages[currentPage].color)
                                .cornerRadius(25)
                        }
                    } else {
                        Button(action: {
                            showOnboarding = false
                        }) {
                            Text("Get Started")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 12)
                                .background(pages[currentPage].color)
                                .cornerRadius(25)
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }

            // Skip button
            VStack {
                HStack {
                    Spacer()

                    if currentPage < pages.count - 1 {
                        Button("Skip") {
                            showOnboarding = false
                        }
                        .foregroundColor(.gray)
                        .padding()
                    }
                }
                Spacer()
            }
        }
    }
}

// MARK: - Onboarding Page View

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(page.color.opacity(0.2))
                    .frame(width: 160, height: 160)

                Image(systemName: page.icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(page.color)
            }

            // Title and description
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)

                Text(page.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Spacer()
            Spacer()
        }
    }
}

// MARK: - Onboarding Page Model

struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(showOnboarding: .constant(true))
    }
}

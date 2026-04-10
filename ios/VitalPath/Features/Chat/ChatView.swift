// ChatView.swift — VitalPath AI
// Conversational wellness coaching with Apple Glass UI, typing indicator,
// mood picker, waveform animation, and crisis escalation.

import SwiftUI

struct ChatView: View {
    @State private var viewModel = ChatViewModel()
    @EnvironmentObject private var appState: AppState
    @FocusState private var inputFocused: Bool
    @Namespace private var bottomAnchor

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedMeshBackground().ignoresSafeArea()

                VStack(spacing: 0) {
                    // ── Navigation header
                    chatHeader

                    // ── Messages
                    ScrollViewReader { proxy in
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: AppSpacing.sm) {
                                Color.clear.frame(height: 12)

                                // Mood picker (beginning of session)
                                if viewModel.showMoodPicker {
                                    moodPickerSection
                                        .transition(.asymmetric(
                                            insertion: .move(edge: .top).combined(with: .opacity),
                                            removal: .move(edge: .top).combined(with: .opacity)
                                        ))
                                }

                                ForEach(viewModel.messages) { message in
                                    MessageBubble(message: message)
                                        .transition(.asymmetric(
                                            insertion: .move(edge: message.role == .user ? .trailing : .leading)
                                                .combined(with: .opacity),
                                            removal: .opacity
                                        ))
                                }

                                if viewModel.isTyping {
                                    TypingIndicator()
                                        .transition(.move(edge: .bottom).combined(with: .opacity))
                                }

                                Color.clear.frame(height: 12).id("bottom")
                            }
                            .padding(.horizontal, AppSpacing.md)
                        }
                        .onChange(of: viewModel.messages.count) { _, _ in
                            withAnimation(AppAnimation.smooth) {
                                proxy.scrollTo("bottom", anchor: .bottom)
                            }
                        }
                        .onChange(of: viewModel.isTyping) { _, _ in
                            withAnimation(AppAnimation.smooth) {
                                proxy.scrollTo("bottom", anchor: .bottom)
                            }
                        }
                    }

                    // ── Input bar
                    inputBar
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $viewModel.showCrisisModal) {
                if let resource = viewModel.crisisResource {
                    CrisisModal(
                        isPresented: $viewModel.showCrisisModal,
                        resource: resource
                    )
                    .presentationDetents([.large])
                    .presentationDragIndicator(.hidden)
                }
            }
        }
    }

    // MARK: - Header

    private var chatHeader: some View {
        HStack(spacing: AppSpacing.sm) {
            // Vita avatar
            ZStack {
                Circle().fill(AppGradient.primaryButton)
                    .frame(width: 44, height: 44)
                Text("V")
                    .font(AppFont.title(20))
                    .foregroundStyle(.white)
            }
            .shadow(color: .vitaPurple.opacity(0.4), radius: 8, x: 0, y: 4)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("Vita")
                        .font(AppFont.title(16))
                        .foregroundStyle(.white)
                    // Online indicator
                    Circle().fill(Color.wellnessSafe)
                        .frame(width: 8, height: 8)
                        .shadow(color: .wellnessSafe.opacity(0.6), radius: 4)
                }
                Text("Wellness Coach • Not a Doctor")
                    .font(AppFont.caption(11))
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            if viewModel.isTyping {
                WaveformView(isActive: true, color: .vitaTeal)
                    .transition(.opacity)
            }

            // New session
            GlassIconButton(icon: "square.and.pencil", size: 40, iconSize: 18) {
                withAnimation(AppAnimation.spring) { viewModel.clearSession() }
            }

            // Language picker
            GlassIconButton(icon: "globe", size: 40, iconSize: 18) {}
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .overlay(alignment: .bottom) {
            Divider().background(.white.opacity(0.08))
        }
    }

    // MARK: - Mood Picker

    private var moodPickerSection: some View {
        GlassCard(cornerRadius: AppRadius.md) {
            VStack(spacing: AppSpacing.sm) {
                Text("How are you feeling right now?")
                    .font(AppFont.body(15))
                    .foregroundStyle(.white)
                HStack(spacing: AppSpacing.xs) {
                    ForEach([
                        ("😔", "Low", 1),
                        ("😐", "Okay", 2),
                        ("🙂", "Good", 3),
                        ("😊", "Great", 4),
                        ("🤩", "Amazing", 5),
                    ], id: \.2) { emoji, label, value in
                        MoodButton(emoji: emoji, label: label, value: value,
                                   selected: Binding(
                                    get: { viewModel.moodBefore },
                                    set: { viewModel.setMood($0 ?? value) }
                                   ))
                    }
                }
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider().background(.white.opacity(0.08))

            HStack(spacing: AppSpacing.sm) {
                // Voice button
                GlassIconButton(
                    icon: viewModel.isRecording ? "waveform" : "mic.fill",
                    size: 44,
                    iconSize: 20,
                    color: viewModel.isRecording ? .vitaCoral : .white
                ) {
                    withAnimation(AppAnimation.spring) {
                        viewModel.isRecording.toggle()
                    }
                }

                // Text field
                TextField("", text: $viewModel.inputText, prompt:
                    Text("Ask Vita anything…")
                        .foregroundStyle(.white.opacity(0.35))
                )
                .font(AppFont.body())
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background {
                    RoundedRectangle(cornerRadius: AppRadius.pill, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay {
                            RoundedRectangle(cornerRadius: AppRadius.pill, style: .continuous)
                                .stroke(
                                    inputFocused
                                        ? Color.vitaTeal.opacity(0.5)
                                        : Color.white.opacity(0.12),
                                    lineWidth: 1.2
                                )
                        }
                }
                .focused($inputFocused)
                .submitLabel(.send)
                .onSubmit {
                    if viewModel.canSend { Task { await viewModel.sendMessage() } }
                }

                // Send button
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    Task { await viewModel.sendMessage() }
                }) {
                    ZStack {
                        Circle()
                            .fill(viewModel.canSend ? AppGradient.primaryButton : LinearGradient(colors: [.white.opacity(0.1)], startPoint: .top, endPoint: .bottom))
                            .frame(width: 44, height: 44)
                        Image(systemName: "arrow.up")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(viewModel.canSend ? .white : .white.opacity(0.3))
                    }
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.canSend)
                .animation(AppAnimation.quick, value: viewModel.canSend)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(.ultraThinMaterial)
        }
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ChatMessage
    @State private var appear = false

    var isUser: Bool { message.role == .user }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isUser { Spacer(minLength: 60) }

            if !isUser {
                // Vita avatar
                ZStack {
                    Circle().fill(AppGradient.primaryButton).frame(width: 28, height: 28)
                    Text("V").font(.system(size: 12, weight: .bold)).foregroundStyle(.white)
                }
                .alignmentGuide(.bottom) { d in d[.bottom] }
            }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(AppFont.body(15))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background {
                        if isUser {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(AppGradient.primaryButton)
                        } else {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                }
                        }
                    }

                Text(message.timestamp, style: .time)
                    .font(AppFont.caption(10))
                    .foregroundStyle(.white.opacity(0.35))
            }
            .scaleEffect(appear ? 1 : 0.85, anchor: isUser ? .bottomTrailing : .bottomLeading)
            .opacity(appear ? 1 : 0)
            .onAppear {
                withAnimation(AppAnimation.bouncy) { appear = true }
            }

            if !isUser { Spacer(minLength: 60) }
        }
    }
}

// MARK: - Typing Indicator

struct TypingIndicator: View {
    @State private var dot1 = false
    @State private var dot2 = false
    @State private var dot3 = false

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ZStack {
                Circle().fill(AppGradient.primaryButton).frame(width: 28, height: 28)
                Text("V").font(.system(size: 12, weight: .bold)).foregroundStyle(.white)
            }

            HStack(spacing: 5) {
                ForEach([(dot1, 0.0), (dot2, 0.15), (dot3, 0.3)], id: \.1) { isUp, delay in
                    Circle()
                        .fill(Color.vitaTeal.opacity(0.8))
                        .frame(width: 8, height: 8)
                        .offset(y: isUp ? -6 : 0)
                        .animation(
                            Animation.easeInOut(duration: 0.5)
                                .repeatForever(autoreverses: true)
                                .delay(delay),
                            value: isUp
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    }
            }

            Spacer(minLength: 60)
        }
        .onAppear {
            dot1 = true
            dot2 = true
            dot3 = true
        }
    }
}

#Preview {
    ChatView().environmentObject(AppState())
}

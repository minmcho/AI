//
//  ChatAssistantView.swift
//  NutriVision AI
//
//  AI chat assistant powered by LLaMA
//

import SwiftUI

struct ChatAssistantView: View {
    @StateObject private var viewModel = AIFeaturesViewModel()
    @State private var messageText: String = ""
    @FocusState private var isInputFocused: Bool

    // Suggested prompts
    let suggestedPrompts = [
        "What's a healthy breakfast?",
        "How can I meal prep?",
        "Best foods for energy?",
        "Vegetarian protein sources?"
    ]

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Chat messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            if viewModel.chatMessages.isEmpty {
                                // Welcome message
                                VStack(spacing: 20) {
                                    Image(systemName: "brain.head.profile")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 80, height: 80)
                                        .foregroundColor(.green)
                                        .padding(.top, 40)

                                    Text("NutriVision AI Assistant")
                                        .font(.title2)
                                        .fontWeight(.bold)

                                    Text("Ask me anything about nutrition, recipes, meal planning, and healthy eating!")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 40)

                                    // Suggested prompts
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Try asking:")
                                            .font(.footnote)
                                            .foregroundColor(.secondary)

                                        ForEach(suggestedPrompts, id: \.self) { prompt in
                                            Button(action: {
                                                messageText = prompt
                                            }) {
                                                HStack {
                                                    Text(prompt)
                                                        .font(.subheadline)
                                                        .foregroundColor(.primary)

                                                    Spacer()

                                                    Image(systemName: "arrow.up.left")
                                                        .font(.caption)
                                                        .foregroundColor(.green)
                                                }
                                                .padding()
                                                .background(Color(.systemGray6))
                                                .cornerRadius(12)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 32)
                                }
                            } else {
                                // Chat messages
                                ForEach(viewModel.chatMessages) { message in
                                    ChatMessageBubble(message: message)
                                        .id(message.id)
                                }

                                // Loading indicator
                                if viewModel.isLoading {
                                    HStack {
                                        ProgressView()
                                            .padding(.leading)

                                        Text("Thinking...")
                                            .font(.caption)
                                            .foregroundColor(.secondary)

                                        Spacer()
                                    }
                                    .padding()
                                }
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.chatMessages.count) { _ in
                        if let lastMessage = viewModel.chatMessages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }

                // Error message
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.red.opacity(0.1))
                }

                // Input area
                VStack(spacing: 0) {
                    Divider()

                    HStack(spacing: 12) {
                        TextField("Ask me anything...", text: $messageText, axis: .vertical)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(20)
                            .focused($isInputFocused)
                            .lineLimit(1...5)
                            .submitLabel(.send)
                            .onSubmit(sendMessage)

                        Button(action: sendMessage) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .frame(width: 40, height: 40)
                            } else {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(messageText.isEmpty ? .gray : .green)
                            }
                        }
                        .disabled(messageText.isEmpty || viewModel.isLoading)
                    }
                    .padding()
                }
                .background(Color(.systemBackground))
            }
            .navigationTitle("AI Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { viewModel.clearChat() }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .disabled(viewModel.chatMessages.isEmpty)
                }
            }
        }
    }

    // MARK: - Methods

    private func sendMessage() {
        guard !messageText.isEmpty else { return }

        let message = messageText
        messageText = ""
        isInputFocused = false

        Task {
            await viewModel.sendMessage(message)
        }
    }
}

// MARK: - Chat Message Bubble

struct ChatMessageBubble: View {
    let message: ChatMessage

    var isUser: Bool {
        message.role == "user"
    }

    var body: some View {
        HStack {
            if isUser { Spacer() }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                HStack(spacing: 8) {
                    if !isUser {
                        Image(systemName: "brain.head.profile")
                            .font(.caption)
                            .foregroundColor(.green)
                    }

                    Text(isUser ? "You" : "AI Assistant")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)

                    if isUser {
                        Image(systemName: "person.circle.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }

                Text(message.content)
                    .font(.body)
                    .padding(12)
                    .background(isUser ? Color.blue : Color.green.opacity(0.2))
                    .foregroundColor(isUser ? .white : .primary)
                    .cornerRadius(16)

                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: isUser ? .trailing : .leading)

            if !isUser { Spacer() }
        }
    }
}

struct ChatAssistantView_Previews: PreviewProvider {
    static var previews: some View {
        ChatAssistantView()
    }
}

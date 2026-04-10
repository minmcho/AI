// ChatViewModel.swift — VitalPath AI

import SwiftUI
import Combine

@MainActor
@Observable
final class ChatViewModel {

    // ── State ────────────────────────────────────────────────
    var messages: [ChatMessage] = []
    var inputText: String = ""
    var isTyping = false             // AI is generating
    var isRecording = false          // Voice input active
    var sessionId: String?
    var currentLanguage: AppLanguage = .en
    var moodBefore: Int?
    var showMoodPicker = true        // Show at start of session
    var error: String?
    var showCrisisModal = false
    var crisisResource: CrisisResource?
    var safetyIntercepted = false

    private let client = GraphQLClient.shared

    // ── Init: greeting message ────────────────────────────────
    init() {
        let greeting = ChatMessage.assistantMessage(
            "Hi! I'm Vita, your wellness coach. I'm here to support your journey — from nutrition tips to mindfulness exercises.\n\nHow are you feeling today? 🌿"
        )
        messages = [greeting]
    }

    // ── Send message ─────────────────────────────────────────
    func sendMessage() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        inputText = ""
        let userMsg = ChatMessage.userMessage(text)
        messages.append(userMsg)
        showMoodPicker = false

        isTyping = true
        error = nil

        do {
            struct MessageData: Decodable { let sendMessage: ChatResponse }
            let variables: [String: Any] = [
                "input": [
                    "message": text,
                    "sessionId": sessionId as Any,
                    "language": currentLanguage.rawValue,
                    "moodBefore": moodBefore as Any,
                ]
            ]

            let data = try await client.execute(
                query: GQL.sendMessage,
                variables: variables,
                type: MessageData.self
            )
            let response = data.sendMessage

            sessionId = response.sessionId
            isTyping = false

            if response.responseType == .crisis {
                // Crisis escalation
                if let resources = response.crisisResources {
                    crisisResource = CrisisResource(
                        country: resources.country,
                        hotline: resources.hotline,
                        name: resources.name,
                        url: resources.url
                    )
                    showCrisisModal = true
                }
                // Add a supportive message
                let supportMsg = ChatMessage.assistantMessage(
                    "I noticed something in what you shared. Please know you're not alone — help is available right now. I've shown you some resources you can reach out to."
                )
                messages.append(supportMsg)
            } else if let msg = response.message {
                var aiMsg = ChatMessage.assistantMessage(msg)
                aiMsg.isAnimating = true
                messages.append(aiMsg)

                // Animate typing reveal
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    self.messages[self.messages.count - 1].isAnimating = false
                }
            }

            safetyIntercepted = response.safetyIntercepted

        } catch {
            isTyping = false
            self.error = error.localizedDescription
            // Add error message
            messages.append(ChatMessage.assistantMessage(
                "I'm having trouble connecting right now. Please try again in a moment. 🌐"
            ))
        }
    }

    func setMood(_ value: Int) {
        withAnimation(AppAnimation.spring) { moodBefore = value }
    }

    func clearSession() {
        sessionId = nil
        messages = [ChatMessage.assistantMessage(
            "Hi! I'm Vita, your wellness coach. How can I support you today? 🌿"
        )]
        showMoodPicker = true
        moodBefore = nil
    }

    var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isTyping
    }
}

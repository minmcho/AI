//
//  VoiceCommandView.swift
//  NutriVision AI
//
//  Voice command interface
//

import SwiftUI

struct VoiceCommandView: View {
    @StateObject private var viewModel = SpeechViewModel()
    @State private var showLanguageSelection = false

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Language selector
                Button(action: { showLanguageSelection = true }) {
                    HStack {
                        Text(viewModel.selectedLanguage.flag)
                            .font(.title2)

                        Text(viewModel.selectedLanguage.displayName)
                            .font(.headline)

                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                }

                Spacer()

                // Recording visualization
                VStack(spacing: 24) {
                    if viewModel.isRecording {
                        // Audio wave animation
                        HStack(spacing: 4) {
                            ForEach(0..<5) { index in
                                AudioBar(isAnimating: viewModel.isRecording)
                                    .animation(
                                        Animation.easeInOut(duration: 0.5)
                                            .repeatForever()
                                            .delay(Double(index) * 0.1),
                                        value: viewModel.isRecording
                                    )
                            }
                        }
                        .frame(height: 60)

                        Text("Listening...")
                            .font(.title3)
                            .fontWeight(.semibold)

                        if !viewModel.transcribedText.isEmpty {
                            Text(viewModel.transcribedText)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }

                        Text(viewModel.formatDuration(viewModel.recordingDuration))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .monospacedDigit()

                    } else {
                        Image(systemName: "mic.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.gray)

                        Text("Tap to start")
                            .font(.title3)
                            .fontWeight(.semibold)

                        Text("Say commands like:\n\"Find recipe for pasta\"\n\"Create meal plan for 7 days\"")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }

                Spacer()

                // Recording button
                RecordingButton(isRecording: $viewModel.isRecording) {
                    toggleRecording()
                }

                // Last command
                if let lastCommand = viewModel.lastCommand {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Last Command")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(lastCommand.command)
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                Text("Intent: \(lastCommand.intent)")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }

                            Spacer()

                            Text(String(format: "%.0f%%", lastCommand.confidence * 100))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 32)
                }

                // Command history button
                if !viewModel.commandHistory.isEmpty {
                    NavigationLink(destination: CommandHistoryView(history: viewModel.commandHistory)) {
                        Text("View History (\(viewModel.commandHistory.count))")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    }
                }

                // Error message
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }
            .padding()
            .navigationTitle("Voice Commands")
            .sheet(isPresented: $showLanguageSelection) {
                LanguageSelectionView(selectedLanguage: $viewModel.selectedLanguage)
            }
        }
    }

    // MARK: - Methods

    private func toggleRecording() {
        if viewModel.isRecording {
            viewModel.stopLocalRecording()

            // Process the command
            if let audioData = viewModel.audioData {
                Task {
                    await viewModel.processVoiceCommand(
                        audioData: audioData,
                        language: viewModel.selectedLanguage
                    )
                }
            }
        } else {
            viewModel.startLocalRecording(language: viewModel.selectedLanguage)
        }
    }
}

// MARK: - Audio Bar

struct AudioBar: View {
    let isAnimating: Bool

    @State private var height: CGFloat = 10

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.green)
            .frame(width: 8, height: height)
            .onAppear {
                if isAnimating {
                    withAnimation {
                        height = CGFloat.random(in: 10...50)
                    }
                }
            }
            .onChange(of: isAnimating) { animating in
                if animating {
                    withAnimation {
                        height = CGFloat.random(in: 10...50)
                    }
                } else {
                    height = 10
                }
            }
    }
}

// MARK: - Command History View

struct CommandHistoryView: View {
    let history: [VoiceCommandResponse]

    var body: some View {
        List(history, id: \.command) { command in
            VStack(alignment: .leading, spacing: 8) {
                Text(command.command)
                    .font(.body)
                    .fontWeight(.medium)

                HStack {
                    Text("Intent: \(command.intent)")
                        .font(.caption)
                        .foregroundColor(.green)

                    Spacer()

                    Text(String(format: "%.0f%% confidence", command.confidence * 100))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if !command.parameters.isEmpty {
                    Text("Parameters: \(command.parameters.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .navigationTitle("Command History")
    }
}

struct VoiceCommandView_Previews: PreviewProvider {
    static var previews: some View {
        VoiceCommandView()
    }
}

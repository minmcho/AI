//
//  RecordingButton.swift
//  NutriVision AI
//
//  Animated recording button component
//

import SwiftUI

struct RecordingButton: View {
    @Binding var isRecording: Bool
    let action: () -> Void

    @State private var animationAmount: CGFloat = 1.0

    var body: some View {
        Button(action: action) {
            ZStack {
                // Pulsing circles when recording
                if isRecording {
                    Circle()
                        .stroke(Color.red.opacity(0.3), lineWidth: 4)
                        .frame(width: 80, height: 80)
                        .scaleEffect(animationAmount)
                        .opacity(2 - animationAmount)

                    Circle()
                        .stroke(Color.red.opacity(0.3), lineWidth: 4)
                        .frame(width: 80, height: 80)
                        .scaleEffect(animationAmount * 0.8)
                        .opacity(2 - animationAmount)
                }

                // Main button
                Circle()
                    .fill(isRecording ? Color.red : Color.green)
                    .frame(width: 70, height: 70)
                    .shadow(color: isRecording ? .red.opacity(0.4) : .green.opacity(0.4), radius: 10)

                // Icon
                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.white)
            }
        }
        .onChange(of: isRecording) { recording in
            if recording {
                withAnimation(Animation.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
                    animationAmount = 2.0
                }
            } else {
                animationAmount = 1.0
            }
        }
    }
}

struct RecordingButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 40) {
            RecordingButton(isRecording: .constant(false)) {
                print("Start recording")
            }

            RecordingButton(isRecording: .constant(true)) {
                print("Stop recording")
            }
        }
    }
}

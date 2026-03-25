import SwiftUI

// MARK: - ViewModel

@MainActor
final class DefectDetectionViewModel: ObservableObject {
    @Published var imageURL = ""
    @Published var result: DefectResult?
    @Published var isLoading = false
    @Published var error: String?

    private let api = CargoAPIClient.shared

    func analyse() {
        guard !imageURL.isEmpty else { return }
        isLoading = true
        error = nil
        result = nil
        Task {
            do {
                result = try await api.detectDefect(imageUrl: imageURL)
            } catch {
                self.error = error.localizedDescription
            }
            isLoading = false
        }
    }
}

// MARK: - View

struct DefectDetectionView: View {
    @StateObject private var vm = DefectDetectionViewModel()
    @State private var showThinking = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Image URL input
                    GroupBox(label: Label("Cargo Image", systemImage: "camera.viewfinder")) {
                        VStack(alignment: .leading, spacing: 12) {
                            TextField("https://example.com/image.jpg",
                                      text: $vm.imageURL)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.URL)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)

                            if vm.imageURL.hasPrefix("http") {
                                AsyncImage(url: URL(string: vm.imageURL)) { phase in
                                    switch phase {
                                    case .success(let img):
                                        img.resizable()
                                           .scaledToFill()
                                           .frame(maxHeight: 200)
                                           .clipShape(RoundedRectangle(cornerRadius: 8))
                                    case .failure:
                                        Label("Cannot load image", systemImage: "photo.badge.exclamationmark")
                                            .foregroundStyle(.secondary)
                                    default:
                                        ProgressView()
                                    }
                                }
                            }

                            Button(action: vm.analyse) {
                                Label("Analyse for Defects", systemImage: "magnifyingglass.circle.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(vm.imageURL.isEmpty || vm.isLoading)
                        }
                    }
                    .padding(.horizontal)

                    // Loading
                    if vm.isLoading {
                        VStack(spacing: 8) {
                            ProgressView()
                            Text("Running Claude Vision analysis…")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                    }

                    // Error
                    if let err = vm.error {
                        Label(err, systemImage: "xmark.circle.fill")
                            .foregroundStyle(.red)
                            .font(.callout)
                            .padding(.horizontal)
                    }

                    // Result
                    if let result = vm.result {
                        DefectResultView(result: result, showThinking: $showThinking)
                            .padding(.horizontal)
                    }

                    // How it works
                    GroupBox(label: Label("How it works", systemImage: "info.circle")) {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach([
                                "Image sent to Claude Vision (claude-opus-4-6)",
                                "Extended thinking analyses defect patterns",
                                "System prompt is cached — repeat calls are 5× faster",
                                "Results: defect type, severity, bounding boxes, action",
                            ], id: \.self) { step in
                                Label(step, systemImage: "arrow.right.circle")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Defect Detection")
        }
    }
}

struct DefectResultView: View {
    let result: DefectResult
    @Binding var showThinking: Bool

    var severityColor: Color {
        switch result.severity.lowercased() {
        case "critical": return .red
        case "high":     return Color(red: 0.9, green: 0.2, blue: 0.1)
        case "medium":   return .orange
        case "low":      return .yellow
        default:         return .gray
        }
    }

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: result.defectFound
                          ? "exclamationmark.triangle.fill"
                          : "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(result.defectFound ? severityColor : .green)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(result.defectFound ? "Defect Detected" : "No Defects Found")
                            .font(.headline)
                        if result.defectFound {
                            Text(result.defectType.replacingOccurrences(of: "_", with: " ").capitalized)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    if result.defectFound {
                        Text(result.severity.capitalized)
                            .font(.caption.bold())
                            .foregroundStyle(severityColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(severityColor.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }

                if result.defectFound {
                    // Confidence
                    HStack {
                        Text("Confidence")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(result.confidence * 100))%")
                            .font(.caption.bold())
                    }
                    ProgressView(value: result.confidence)
                        .tint(severityColor)
                }

                // Description
                if !result.description.isEmpty {
                    Divider()
                    Text(result.description)
                        .font(.callout)
                }

                // Recommended action
                if !result.recommendedAction.isEmpty {
                    Divider()
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Recommended Action")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(result.recommendedAction)
                                .font(.subheadline.bold())
                        }
                    } icon: {
                        Image(systemName: "checklist")
                            .foregroundStyle(.blue)
                    }
                }

                // Claude thinking (collapsible)
                if let thinking = result.reasoning, !thinking.isEmpty {
                    Divider()
                    Button(action: { showThinking.toggle() }) {
                        HStack {
                            Label("Claude's Reasoning",
                                  systemImage: "brain.head.profile")
                                .font(.subheadline.bold())
                                .foregroundStyle(.purple)
                            Spacer()
                            Image(systemName: showThinking ? "chevron.up" : "chevron.down")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                    }
                    if showThinking {
                        ScrollView {
                            Text(String(thinking.prefix(2000)))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: 200)
                        .padding(8)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }

                // Metadata
                HStack {
                    Text("Model: \(result.modelVersion)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Spacer()
                    Text("\(result.latencyMs)ms")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    if result.cacheReadTokens > 0 {
                        Text("⚡ cached")
                            .font(.caption2.bold())
                            .foregroundStyle(.green)
                    }
                }
            }
        }
    }
}

#Preview { DefectDetectionView() }

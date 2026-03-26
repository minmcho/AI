import SwiftUI

struct TranslationView: View {
    @State private var vm = TranslationViewModel()
    @State private var showSourcePicker = false
    @State private var showTargetPicker = false
    @State private var showMultiPicker  = false
    @State private var showHistory      = false
    @State private var copiedSource     = false
    @State private var copiedTarget     = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 0) {
                        modeToggle
                            .padding(.horizontal)
                            .padding(.top, 8)

                        languageBar
                            .padding(.horizontal)
                            .padding(.top, 12)

                        sourceCard
                            .padding(.horizontal)
                            .padding(.top, 12)

                        if vm.isMultiMode {
                            multiResultsSection
                                .padding(.horizontal)
                                .padding(.top, 12)
                        } else {
                            targetCard
                                .padding(.horizontal)
                                .padding(.top, 12)
                        }

                        if let error = vm.errorMessage {
                            errorBanner(error)
                                .padding(.horizontal)
                                .padding(.top, 10)
                        }
                    }
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Myanmar Translate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showHistory = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundStyle(.cyan)
                    }
                }
                if vm.isMultiMode {
                    ToolbarItem(placement: .secondaryAction) {
                        Button {
                            showMultiPicker = true
                        } label: {
                            Label("Select Languages", systemImage: "list.bullet.circle")
                                .foregroundStyle(.cyan)
                        }
                    }
                }
            }
            .sheet(isPresented: $showSourcePicker) {
                LanguagePickerSheet(
                    title: "Source Language",
                    languages: vm.languages,
                    exclude: vm.targetLang,
                    selection: $vm.sourceLang
                )
            }
            .sheet(isPresented: $showTargetPicker) {
                LanguagePickerSheet(
                    title: "Target Language",
                    languages: vm.languages,
                    exclude: vm.sourceLang,
                    selection: $vm.targetLang
                )
            }
            .sheet(isPresented: $showMultiPicker) {
                MultiLanguagePickerSheet(
                    languages: vm.languages,
                    excludeCode: vm.sourceLang.code,
                    selected: $vm.selectedMultiTargets
                )
            }
            .navigationDestination(isPresented: $showHistory) {
                TranslationHistoryView(vm: vm)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Mode toggle

    private var modeToggle: some View {
        Picker("Mode", selection: $vm.isMultiMode) {
            Text("Single").tag(false)
            Text("Multi-language").tag(true)
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Language bar

    private var languageBar: some View {
        HStack(spacing: 0) {
            langButton(lang: vm.sourceLang, role: "From") {
                showSourcePicker = true
            }

            Spacer()

            Button {
                withAnimation(.spring(duration: 0.35)) { vm.swapLanguages() }
            } label: {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.cyan)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color(.systemGray6).opacity(0.2)))
            }

            Spacer()

            if vm.isMultiMode {
                Button {
                    showMultiPicker = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "globe")
                        Text("\(vm.selectedMultiTargets.count) langs")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(.cyan)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6).opacity(0.2)))
                }
                .frame(maxWidth: .infinity)
            } else {
                langButton(lang: vm.targetLang, role: "To") {
                    showTargetPicker = true
                }
            }
        }
    }

    private func langButton(lang: MyanmarLanguage, role: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(role)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.4))
                HStack(spacing: 4) {
                    Text(lang.flag)
                    Text(lang.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6).opacity(0.2)))
        }
    }

    // MARK: - Source card

    private var sourceCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                if vm.sourceText.isEmpty {
                    Text("Enter \(vm.sourceLang.name) text…")
                        .foregroundStyle(.white.opacity(0.3))
                        .font(.body)
                        .padding(14)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $vm.sourceText)
                    .font(.body)
                    .foregroundStyle(.white)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 130)
                    .padding(10)
            }
            .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemGray6).opacity(0.15)))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))

            HStack {
                Text("\(vm.sourceText.count) / 2000")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.3))

                Spacer()

                // Copy source
                actionButton(
                    icon: copiedSource ? "checkmark" : "doc.on.doc",
                    color: copiedSource ? .green : .white.opacity(0.5)
                ) {
                    UIPasteboard.general.string = vm.sourceText
                    withAnimation { copiedSource = true }
                    Task {
                        try? await Task.sleep(for: .seconds(1.5))
                        await MainActor.run { withAnimation { copiedSource = false } }
                    }
                }

                // Clear
                if !vm.sourceText.isEmpty {
                    actionButton(icon: "xmark.circle", color: .white.opacity(0.5)) {
                        vm.sourceText = ""
                        vm.translatedText = ""
                        vm.multiResults = []
                    }
                }

                // Mic
                Button {
                    Task {
                        if vm.isRecording {
                            await vm.stopRecording()
                        } else {
                            await vm.startRecording()
                        }
                    }
                } label: {
                    Image(systemName: vm.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(vm.isRecording ? .red : .cyan)
                        .symbolEffect(.pulse, isActive: vm.isRecording)
                }
                .padding(.leading, 4)

                // Translate button (manual trigger)
                Button {
                    Task {
                        vm.isMultiMode ? await vm.translateToAll() : await vm.translate()
                    }
                } label: {
                    HStack(spacing: 4) {
                        if vm.isTranslating {
                            ProgressView().tint(.white).scaleEffect(0.7)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                        }
                        Text("Translate")
                            .font(.footnote.weight(.semibold))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(Color.cyan))
                    .foregroundStyle(.black)
                }
                .disabled(vm.isTranslating || vm.sourceText.isEmpty)
                .opacity(vm.sourceText.isEmpty ? 0.4 : 1)
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Single target card

    private var targetCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                if vm.isTranslating {
                    HStack(spacing: 10) {
                        ProgressView().tint(.cyan)
                        Text("Translating…")
                            .foregroundStyle(.white.opacity(0.5))
                            .font(.body)
                    }
                    .padding(14)
                } else if vm.translatedText.isEmpty {
                    Text("Translation will appear here")
                        .foregroundStyle(.white.opacity(0.2))
                        .font(.body)
                        .padding(14)
                } else {
                    Text(vm.translatedText)
                        .font(.body)
                        .foregroundStyle(.cyan)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
            }
            .frame(minHeight: 130, alignment: .topLeading)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.cyan.opacity(0.07)))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.cyan.opacity(0.2), lineWidth: 1))

            if !vm.translatedText.isEmpty {
                HStack {
                    Spacer()
                    // Share
                    actionButton(icon: "square.and.arrow.up", color: .white.opacity(0.5)) {
                        let text = "\(vm.sourceLang.flag) \(vm.sourceText)\n\(vm.targetLang.flag) \(vm.translatedText)"
                        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
                        UIApplication.topViewController()?.present(av, animated: true)
                    }
                    // Copy
                    actionButton(
                        icon: copiedTarget ? "checkmark" : "doc.on.doc",
                        color: copiedTarget ? .green : .white.opacity(0.5)
                    ) {
                        UIPasteboard.general.string = vm.translatedText
                        withAnimation { copiedTarget = true }
                        Task {
                            try? await Task.sleep(for: .seconds(1.5))
                            await MainActor.run { withAnimation { copiedTarget = false } }
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
    }

    // MARK: - Multi results

    private var multiResultsSection: some View {
        VStack(spacing: 10) {
            if vm.isTranslating {
                HStack(spacing: 10) {
                    ProgressView().tint(.cyan)
                    Text("Translating to \(vm.selectedMultiTargets.count) languages…")
                        .foregroundStyle(.white.opacity(0.5))
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.cyan.opacity(0.07)))
            } else if vm.multiResults.isEmpty && !vm.sourceText.isEmpty {
                Text("Tap Translate to see all languages")
                    .foregroundStyle(.white.opacity(0.25))
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }

            ForEach(vm.multiResults) { result in
                MultiResultCard(result: result)
            }
        }
    }

    // MARK: - Error banner

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(message)
                .font(.caption)
                .foregroundStyle(.white)
            Spacer()
            Button { vm.errorMessage = nil } label: {
                Image(systemName: "xmark").font(.caption2).foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.orange.opacity(0.15)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.orange.opacity(0.3), lineWidth: 1))
    }

    // MARK: - Helpers

    private func actionButton(icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 17))
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
        }
    }
}

// MARK: - Multi result card

private struct MultiResultCard: View {
    let result: MultiTranslationResult
    @State private var copied = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(result.language.flag)
                .font(.title2)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(result.language.name)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.5))
                Text(result.translatedText)
                    .font(.subheadline)
                    .foregroundStyle(.cyan)
                    .textSelection(.enabled)
            }

            Spacer(minLength: 0)

            Button {
                UIPasteboard.general.string = result.translatedText
                withAnimation { copied = true }
                Task {
                    try? await Task.sleep(for: .seconds(1.5))
                    await MainActor.run { withAnimation { copied = false } }
                }
            } label: {
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    .font(.footnote)
                    .foregroundStyle(copied ? .green : .white.opacity(0.4))
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.cyan.opacity(0.06)))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.cyan.opacity(0.15), lineWidth: 1))
    }
}

// MARK: - UIApplication helper for share sheet

private extension UIApplication {
    static func topViewController(_ base: UIViewController? = UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .flatMap { $0.windows }
        .first(where: \.isKeyWindow)?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController { return topViewController(nav.visibleViewController) }
        if let tab = base as? UITabBarController { return topViewController(tab.selectedViewController) }
        if let presented = base?.presentedViewController { return topViewController(presented) }
        return base
    }
}

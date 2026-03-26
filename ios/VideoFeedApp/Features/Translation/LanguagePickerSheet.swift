import SwiftUI

// MARK: - Single-language picker

struct LanguagePickerSheet: View {
    let title: String
    let languages: [MyanmarLanguage]
    let exclude: MyanmarLanguage?
    @Binding var selection: MyanmarLanguage
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""

    private var filtered: [MyanmarLanguage] {
        let list = languages.filter { $0.code != exclude?.code }
        guard !search.isEmpty else { return list }
        return list.filter { $0.name.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        NavigationStack {
            List(filtered) { lang in
                Button {
                    selection = lang
                    dismiss()
                } label: {
                    HStack(spacing: 14) {
                        Text(lang.flag).font(.title2)
                        Text(lang.name)
                            .foregroundStyle(.white)
                        Spacer()
                        if lang == selection {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.cyan)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .listRowBackground(Color(.systemGray6).opacity(0.15))
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.black)
            .searchable(text: $search, prompt: "Search language")
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.cyan)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Multi-language picker

struct MultiLanguagePickerSheet: View {
    let languages: [MyanmarLanguage]
    let excludeCode: String
    @Binding var selected: Set<String>
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""

    private var filtered: [MyanmarLanguage] {
        let list = languages.filter { $0.code != excludeCode }
        guard !search.isEmpty else { return list }
        return list.filter { $0.name.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        NavigationStack {
            List(filtered) { lang in
                Button {
                    if selected.contains(lang.code) {
                        selected.remove(lang.code)
                    } else {
                        selected.insert(lang.code)
                    }
                } label: {
                    HStack(spacing: 14) {
                        Text(lang.flag).font(.title2)
                        Text(lang.name).foregroundStyle(.white)
                        Spacer()
                        Image(systemName: selected.contains(lang.code) ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(selected.contains(lang.code) ? .cyan : .gray)
                    }
                    .contentShape(Rectangle())
                }
                .listRowBackground(Color(.systemGray6).opacity(0.15))
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.black)
            .searchable(text: $search, prompt: "Search language")
            .navigationTitle("Target Languages (\(selected.count))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.cyan)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

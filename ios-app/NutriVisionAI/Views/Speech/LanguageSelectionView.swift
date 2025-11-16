//
//  LanguageSelectionView.swift
//  NutriVision AI
//
//  Language selection view
//

import SwiftUI

struct LanguageSelectionView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedLanguage: Language

    let languages: [Language] = [.en, .zh, .ja, .ko, .th, .my]

    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(languages, id: \.self) { language in
                        LanguageRow(
                            language: language,
                            isSelected: selectedLanguage == language
                        ) {
                            selectedLanguage = language
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                } header: {
                    Text("Select Language")
                } footer: {
                    Text("Choose your preferred language for voice commands and speech features")
                }
            }
            .navigationTitle("Language")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct LanguageRow: View {
    let language: Language
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Text(language.flag)
                    .font(.largeTitle)

                VStack(alignment: .leading, spacing: 4) {
                    Text(language.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(language.rawValue.uppercased())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                }
            }
            .padding(.vertical, 8)
        }
    }
}

struct LanguageSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        LanguageSelectionView(selectedLanguage: .constant(.en))
    }
}

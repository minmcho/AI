//
//  LanguagePicker.swift
//  NutriVision AI
//
//  Reusable language selection component
//

import SwiftUI

struct LanguagePicker: View {
    @Binding var selectedLanguage: Language

    var body: some View {
        Menu {
            ForEach(Language.allCases, id: \.self) { language in
                Button(action: { selectedLanguage = language }) {
                    HStack {
                        Text("\(language.flag) \(language.displayName)")
                        if selectedLanguage == language {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack {
                Text(selectedLanguage.flag)
                    .font(.title2)
                Text(selectedLanguage.displayName)
                    .font(.subheadline)
                Image(systemName: "chevron.down")
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.blue.opacity(0.1))
            .foregroundColor(.blue)
            .cornerRadius(8)
        }
    }
}

struct LanguagePicker_Previews: PreviewProvider {
    static var previews: some View {
        LanguagePicker(selectedLanguage: .constant(.en))
    }
}

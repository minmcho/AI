//
//  ImagePickerService.swift
//  NutriVision AI
//
//  Image picker and camera service
//

import SwiftUI
import UIKit

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    var sourceType: UIImagePickerController.SourceType = .photoLibrary

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }

            parent.presentationMode.wrappedValue.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Camera View

struct CameraView: View {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ImagePicker(selectedImage: $selectedImage, sourceType: .camera)
            .ignoresSafeArea()
    }
}

// MARK: - Photo Library View

struct PhotoLibraryView: View {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ImagePicker(selectedImage: $selectedImage, sourceType: .photoLibrary)
            .ignoresSafeArea()
    }
}

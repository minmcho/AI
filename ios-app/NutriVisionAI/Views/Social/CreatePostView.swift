//
//  CreatePostView.swift
//  NutriVision AI
//
//  Create and share social posts
//

import SwiftUI
import PhotosUI

struct CreatePostView: View {
    @StateObject private var viewModel = CreatePostViewModel()
    @Environment(\.presentationMode) var presentationMode

    @State private var caption: String = ""
    @State private var selectedMeal: Meal?
    @State private var selectedRecipe: Recipe?
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingMealPicker = false
    @State private var showingRecipePicker = false
    @State private var imagePickerSourceType: UIImagePickerController.SourceType = .photoLibrary

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Image Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Photo")
                            .font(.headline)

                        if let image = selectedImage {
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 300)
                                    .clipped()
                                    .cornerRadius(12)

                                Button(action: {
                                    selectedImage = nil
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .background(Circle().fill(Color.black.opacity(0.6)))
                                }
                                .padding(8)
                            }
                        } else {
                            HStack(spacing: 12) {
                                Button(action: {
                                    imagePickerSourceType = .camera
                                    showingImagePicker = true
                                }) {
                                    VStack {
                                        Image(systemName: "camera.fill")
                                            .font(.title)
                                        Text("Camera")
                                            .font(.caption)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(12)
                                }

                                Button(action: {
                                    imagePickerSourceType = .photoLibrary
                                    showingImagePicker = true
                                }) {
                                    VStack {
                                        Image(systemName: "photo.fill")
                                            .font(.title)
                                        Text("Library")
                                            .font(.caption)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(12)
                                }
                            }
                        }
                    }

                    // Caption
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Caption")
                            .font(.headline)

                        TextEditor(text: $caption)
                            .frame(height: 120)
                            .padding(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .overlay(
                                Group {
                                    if caption.isEmpty {
                                        Text("What's on your plate?")
                                            .foregroundColor(.gray.opacity(0.5))
                                            .padding(.leading, 12)
                                            .padding(.top, 16)
                                    }
                                },
                                alignment: .topLeading
                            )
                    }

                    // Link Meal
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Link to Meal (Optional)")
                            .font(.headline)

                        if let meal = selectedMeal {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(meal.name)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    if let calories = meal.calories {
                                        Text("\(Int(calories)) kcal")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }

                                Spacer()

                                Button(action: {
                                    selectedMeal = nil
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        } else {
                            Button(action: {
                                showingMealPicker = true
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Link a Meal")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .foregroundColor(.primary)
                                .cornerRadius(12)
                            }
                        }
                    }

                    // Link Recipe
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Link to Recipe (Optional)")
                            .font(.headline)

                        if let recipe = selectedRecipe {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(recipe.name)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    if let cuisine = recipe.cuisine {
                                        Text(cuisine)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }

                                Spacer()

                                Button(action: {
                                    selectedRecipe = nil
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        } else {
                            Button(action: {
                                showingRecipePicker = true
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Link a Recipe")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .foregroundColor(.primary)
                                .cornerRadius(12)
                            }
                        }
                    }

                    // Create Post Button
                    Button(action: {
                        Task {
                            await viewModel.createPost(
                                caption: caption,
                                image: selectedImage,
                                mealId: selectedMeal?.id,
                                recipeId: selectedRecipe?.id
                            )
                            if viewModel.errorMessage == nil {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "paperplane.fill")
                                Text("Share Post")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canPost ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(!canPost || viewModel.isLoading)

                    // Error Message
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Create Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage, sourceType: imagePickerSourceType)
            }
            .sheet(isPresented: $showingMealPicker) {
                MealPickerView(selectedMeal: $selectedMeal)
            }
            .sheet(isPresented: $showingRecipePicker) {
                RecipePickerView(selectedRecipe: $selectedRecipe)
            }
        }
    }

    private var canPost: Bool {
        !caption.isEmpty && selectedImage != nil
    }
}

// MARK: - Image Picker

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    let sourceType: UIImagePickerController.SourceType

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
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

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Meal Picker

struct MealPickerView: View {
    @Binding var selectedMeal: Meal?
    @Environment(\.presentationMode) var presentationMode
    @State private var meals: [Meal] = [] // TODO: Load from API

    var body: some View {
        NavigationView {
            List(meals) { meal in
                Button(action: {
                    selectedMeal = meal
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(meal.name)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            if let calories = meal.calories {
                                Text("\(Int(calories)) kcal")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        if selectedMeal?.id == meal.id {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Select Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Recipe Picker

struct RecipePickerView: View {
    @Binding var selectedRecipe: Recipe?
    @Environment(\.presentationMode) var presentationMode
    @State private var recipes: [Recipe] = [] // TODO: Load from API

    var body: some View {
        NavigationView {
            List(recipes) { recipe in
                Button(action: {
                    selectedRecipe = recipe
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(recipe.name)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            if let cuisine = recipe.cuisine {
                                Text(cuisine)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        if selectedRecipe?.id == recipe.id {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Select Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - ViewModel

@MainActor
class CreatePostViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let socialService = SocialService()

    func createPost(caption: String, image: UIImage?, mealId: String?, recipeId: String?) async {
        isLoading = true
        errorMessage = nil

        // Validate
        if let error = ValidationUtils.lengthValidationError(caption, fieldName: "Caption", min: 1, max: 500) {
            errorMessage = error
            isLoading = false
            return
        }

        guard let image = image else {
            errorMessage = "Please select an image"
            isLoading = false
            return
        }

        // Compress image
        guard let imageData = ImageUtils.compressToMaxSize(image, maxSizeKB: 2048) else {
            errorMessage = "Failed to process image"
            isLoading = false
            return
        }

        do {
            _ = try await socialService.createPost(
                caption: caption,
                imageData: imageData,
                mealId: mealId,
                recipeId: recipeId
            )
        } catch {
            errorMessage = "Failed to create post: \(error.localizedDescription)"
        }

        isLoading = false
    }
}

// MARK: - Preview

struct CreatePostView_Previews: PreviewProvider {
    static var previews: some View {
        CreatePostView()
    }
}

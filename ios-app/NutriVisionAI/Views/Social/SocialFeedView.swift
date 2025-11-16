//
//  SocialFeedView.swift
//  NutriVision AI
//
//  Social feed and community view
//

import SwiftUI

struct SocialFeedView: View {
    @StateObject private var viewModel = MealPlanViewModel()
    @State private var showCreatePost = false

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    if viewModel.isLoading && viewModel.socialPosts.isEmpty {
                        LoadingView(message: "Loading feed...")
                            .frame(height: 200)
                    } else if viewModel.socialPosts.isEmpty {
                        EmptySocialFeedView {
                            showCreatePost = true
                        }
                    } else {
                        ForEach(viewModel.socialPosts) { post in
                            SocialPostCard(post: post)
                        }

                        // Load more
                        if !viewModel.isLoading {
                            Button(action: loadMore) {
                                Text("Load More")
                                    .foregroundColor(.green)
                            }
                            .padding()
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Community")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showCreatePost = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.green)
                    }
                }
            }
            .refreshable {
                await viewModel.loadSocialFeed()
            }
            .sheet(isPresented: $showCreatePost) {
                CreatePostView(viewModel: viewModel)
            }
            .task {
                if viewModel.socialPosts.isEmpty {
                    await viewModel.loadSocialFeed()
                }
            }
        }
    }

    private func loadMore() {
        Task {
            await viewModel.loadSocialFeed(
                limit: 20,
                offset: viewModel.socialPosts.count
            )
        }
    }
}

// MARK: - Social Post Card

struct SocialPostCard: View {
    let post: MealPlanService.SocialPost

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 12) {
                // Avatar
                Circle()
                    .fill(LinearGradient(
                        colors: [.green.opacity(0.7), .blue.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(post.username.prefix(1).uppercased())
                            .font(.headline)
                            .foregroundColor(.white)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(post.username)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(timeAgo(from: post.createdAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: {}) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.gray)
                }
            }

            // Content
            Text(post.content)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)

            // Image
            if let imageUrl = post.imageUrl {
                AsyncImage(url: URL(string: imageUrl)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(height: 200)
                            .clipped()
                            .cornerRadius(12)

                    case .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 200)
                            .cornerRadius(12)
                            .overlay(ProgressView())

                    case .failure:
                        EmptyView()

                    @unknown default:
                        EmptyView()
                    }
                }
            }

            // Actions
            HStack(spacing: 24) {
                Button(action: {}) {
                    HStack(spacing: 6) {
                        Image(systemName: "heart")
                        Text("\(post.likes)")
                            .font(.subheadline)
                    }
                    .foregroundColor(.gray)
                }

                Button(action: {}) {
                    HStack(spacing: 6) {
                        Image(systemName: "bubble.right")
                        Text("\(post.comments)")
                            .font(.subheadline)
                    }
                    .foregroundColor(.gray)
                }

                Spacer()

                Button(action: {}) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.gray)
                }
            }
            .font(.subheadline)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
    }

    private func timeAgo(from dateString: String) -> String {
        // Simple implementation - you can use a proper date formatter
        return "2h ago"
    }
}

// MARK: - Empty Social Feed View

struct EmptySocialFeedView: View {
    let onCreate: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.3.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.green)
                .padding(.top, 60)

            Text("No Posts Yet")
                .font(.title2)
                .fontWeight(.bold)

            Text("Share your meals and nutrition journey with the community")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            CustomButton(
                title: "Create Post",
                icon: "plus",
                style: .primary,
                action: onCreate
            )
            .padding(.horizontal, 32)
        }
    }
}

// MARK: - Create Post View

struct CreatePostView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: MealPlanViewModel

    @State private var content: String = ""
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Content editor
                TextEditor(text: $content)
                    .frame(height: 200)
                    .padding()
                    .overlay(
                        Group {
                            if content.isEmpty {
                                Text("Share your meal or nutrition tip...")
                                    .foregroundColor(.secondary)
                                    .padding()
                                    .allowsHitTesting(false)
                            }
                        },
                        alignment: .topLeading
                    )

                // Image preview
                if let image = selectedImage {
                    VStack(spacing: 12) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .cornerRadius(12)

                        Button(action: { selectedImage = nil }) {
                            Text("Remove Image")
                                .foregroundColor(.red)
                        }
                    }
                    .padding()
                }

                Divider()

                // Actions
                HStack(spacing: 20) {
                    Button(action: { showImagePicker = true }) {
                        Label("Photo", systemImage: "photo")
                            .foregroundColor(.green)
                    }

                    Spacer()
                }
                .padding()

                Spacer()

                // Error message
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .navigationTitle("Create Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Post") {
                        createPost()
                    }
                    .disabled(content.isEmpty || viewModel.isLoading)
                }
            }
            .sheet(isPresented: $showImagePicker) {
                PhotoLibraryView(selectedImage: $selectedImage)
            }
        }
    }

    private func createPost() {
        Task {
            // TODO: Upload image and get URL
            let imageUrl: String? = nil

            let success = await viewModel.createPost(
                content: content,
                imageUrl: imageUrl
            )

            if success {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

struct SocialFeedView_Previews: PreviewProvider {
    static var previews: some View {
        SocialFeedView()
    }
}

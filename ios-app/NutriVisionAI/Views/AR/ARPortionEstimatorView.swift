//
//  ARPortionEstimatorView.swift
//  NutriVision AI
//
//  AR-based food portion estimation
//

import SwiftUI
import ARKit
import RealityKit

struct ARPortionEstimatorView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = ARPortionEstimatorViewModel()

    var body: some View {
        ZStack {
            // AR View
            ARViewContainer(viewModel: viewModel)
                .edgesIgnoringSafeArea(.all)

            // Overlay UI
            VStack {
                // Header
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .shadow(radius: 3)
                    }

                    Spacer()

                    Text("AR Portion Estimator")
                        .font(.headline)
                        .foregroundColor(.white)
                        .shadow(radius: 3)

                    Spacer()

                    Button(action: {
                        viewModel.resetMeasurement()
                    }) {
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .shadow(radius: 3)
                    }
                }
                .padding()

                Spacer()

                // Instructions
                if !viewModel.isPlaneDetected {
                    VStack(spacing: 16) {
                        Image(systemName: "iphone.radiowaves.left.and.right")
                            .font(.system(size: 50))
                            .foregroundColor(.white)

                        Text("Move your device slowly")
                            .font(.headline)
                            .foregroundColor(.white)

                        Text("Looking for horizontal surfaces...")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding()
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(16)
                    .padding()
                }

                // Measurement info
                if viewModel.isPlaneDetected {
                    VStack(spacing: 12) {
                        if viewModel.isMeasuring {
                            Text("Tap to place reference object")
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.green.opacity(0.8))
                                .cornerRadius(12)
                        }

                        if let measurement = viewModel.currentMeasurement {
                            MeasurementInfoCard(measurement: measurement)
                        }
                    }
                    .padding()
                }

                // Actions
                if viewModel.isPlaneDetected {
                    VStack(spacing: 16) {
                        // Reference object selector
                        if !viewModel.isMeasuring {
                            ReferenceObjectPicker(
                                selectedObject: $viewModel.selectedReferenceObject
                            ) {
                                viewModel.startMeasurement()
                            }
                            .padding(.horizontal)
                        }

                        // Confirm button
                        if let _ = viewModel.currentMeasurement {
                            CustomButton(
                                title: "Use This Measurement",
                                icon: "checkmark.circle.fill",
                                style: .primary
                            ) {
                                confirmMeasurement()
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 32)
                }
            }

            // Loading overlay
            if viewModel.isProcessing {
                Color.black.opacity(0.6)
                    .edgesIgnoringSafeArea(.all)

                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))

                    Text("Analyzing...")
                        .foregroundColor(.white)
                        .font(.headline)
                }
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
    }

    private func confirmMeasurement() {
        // Use the measurement
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - AR View Container

struct ARViewContainer: UIViewRepresentable {
    @ObservedObject var viewModel: ARPortionEstimatorViewModel

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        viewModel.setupARView(arView)
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}
}

// MARK: - Measurement Info Card

struct MeasurementInfoCard: View {
    let measurement: PortionMeasurement

    var body: some View {
        VStack(spacing: 12) {
            Text("Estimated Portion")
                .font(.headline)
                .foregroundColor(.white)

            HStack(spacing: 20) {
                MeasurementItem(
                    label: "Volume",
                    value: String(format: "%.0f ml", measurement.volumeML),
                    icon: "drop.fill"
                )

                MeasurementItem(
                    label: "Weight",
                    value: String(format: "%.0f g", measurement.estimatedWeightG),
                    icon: "scalemass.fill"
                )

                MeasurementItem(
                    label: "Servings",
                    value: String(format: "%.1f", measurement.servings),
                    icon: "fork.knife"
                )
            }

            if let calories = measurement.estimatedCalories {
                Text("\(calories) cal")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(Color.black.opacity(0.8))
        .cornerRadius(16)
    }
}

struct MeasurementItem: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(.green)

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

// MARK: - Reference Object Picker

struct ReferenceObjectPicker: View {
    @Binding var selectedObject: ReferenceObject
    let onStart: () -> Void

    let referenceObjects: [ReferenceObject] = [
        .creditCard,
        .coin,
        .hand,
        .cup
    ]

    var body: some View {
        VStack(spacing: 12) {
            Text("Select Reference Object")
                .font(.subheadline)
                .foregroundColor(.white)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(referenceObjects, id: \.self) { object in
                        ReferenceObjectButton(
                            object: object,
                            isSelected: selectedObject == object
                        ) {
                            selectedObject = object
                            onStart()
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.8))
        .cornerRadius(16)
    }
}

struct ReferenceObjectButton: View {
    let object: ReferenceObject
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: object.icon)
                    .font(.title)
                    .foregroundColor(isSelected ? .white : .white.opacity(0.6))

                Text(object.name)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : .white.opacity(0.6))

                Text(object.size)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .green : .white.opacity(0.4))
            }
            .padding()
            .background(isSelected ? Color.green : Color.white.opacity(0.2))
            .cornerRadius(12)
        }
    }
}

// MARK: - ViewModel

class ARPortionEstimatorViewModel: NSObject, ObservableObject {
    @Published var isPlaneDetected = false
    @Published var isMeasuring = false
    @Published var isProcessing = false
    @Published var currentMeasurement: PortionMeasurement?
    @Published var selectedReferenceObject: ReferenceObject = .creditCard
    @Published var showError = false
    @Published var errorMessage: String?

    private var arView: ARView?
    private var referenceAnchor: AnchorEntity?
    private var foodAnchor: AnchorEntity?

    func setupARView(_ arView: ARView) {
        self.arView = arView

        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.environmentTexturing = .automatic

        arView.session.delegate = self
        arView.session.run(config)

        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
    }

    func startMeasurement() {
        isMeasuring = true
        currentMeasurement = nil
    }

    func resetMeasurement() {
        isMeasuring = false
        currentMeasurement = nil
        referenceAnchor?.removeFromParent()
        foodAnchor?.removeFromParent()
        referenceAnchor = nil
        foodAnchor = nil
    }

    @objc private func handleTap(_ sender: UITapGestureRecognizer) {
        guard let arView = arView, isMeasuring else { return }

        let location = sender.location(in: arView)

        // Perform raycast
        let results = arView.raycast(
            from: location,
            allowing: .estimatedPlane,
            alignment: .horizontal
        )

        guard let result = results.first else { return }

        if referenceAnchor == nil {
            // Place reference object
            placeReferenceObject(at: result)
        } else {
            // Place food item
            placeFoodItem(at: result)
        }
    }

    private func placeReferenceObject(at result: ARRaycastResult) {
        guard let arView = arView else { return }

        let anchor = AnchorEntity(world: result.worldTransform)

        // Create reference box
        let mesh = MeshResource.generateBox(
            size: selectedReferenceObject.dimensions,
            cornerRadius: 0.002
        )
        let material = SimpleMaterial(color: .green.withAlphaComponent(0.7), isMetallic: false)
        let modelEntity = ModelEntity(mesh: mesh, materials: [material])

        anchor.addChild(modelEntity)
        arView.scene.addAnchor(anchor)

        referenceAnchor = anchor
    }

    private func placeFoodItem(at result: ARRaycastResult) {
        guard let arView = arView else { return }

        let anchor = AnchorEntity(world: result.worldTransform)

        // Create food placeholder (sphere for now)
        let mesh = MeshResource.generateSphere(radius: 0.05)
        let material = SimpleMaterial(color: .orange.withAlphaComponent(0.7), isMetallic: false)
        let modelEntity = ModelEntity(mesh: mesh, materials: [material])

        anchor.addChild(modelEntity)
        arView.scene.addAnchor(anchor)

        foodAnchor = anchor

        // Calculate portion
        calculatePortion()
    }

    private func calculatePortion() {
        guard let referenceAnchor = referenceAnchor,
              let foodAnchor = foodAnchor else { return }

        isProcessing = true

        // Get positions
        let referencePos = referenceAnchor.position
        let foodPos = foodAnchor.position

        // Calculate distance and scale
        let distance = simd_distance(referencePos, foodPos)
        let scale = selectedReferenceObject.realSize / selectedReferenceObject.dimensions.x

        // Estimate volume (simplified - assuming sphere)
        let radius = 0.05 * scale // 5cm radius scaled
        let volume = (4.0/3.0) * .pi * pow(radius, 3) * 1000000 // Convert to mL

        // Estimate weight (assuming density of water ~1 g/mL)
        let weight = volume * 0.8 // Assume food density is 0.8 g/mL

        // Calculate servings (assuming 150g per serving)
        let servings = weight / 150.0

        // Estimate calories (rough approximation)
        let calories = Int(weight * 1.5) // ~1.5 cal per gram

        let measurement = PortionMeasurement(
            volumeML: volume,
            estimatedWeightG: weight,
            servings: servings,
            estimatedCalories: calories
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.currentMeasurement = measurement
            self.isMeasuring = false
            self.isProcessing = false
        }
    }
}

// MARK: - AR Session Delegate

extension ARPortionEstimatorViewModel: ARSessionDelegate {
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            if anchor is ARPlaneAnchor {
                DispatchQueue.main.async {
                    self.isPlaneDetected = true
                }
            }
        }
    }
}

// MARK: - Models

struct PortionMeasurement {
    let volumeML: Double
    let estimatedWeightG: Double
    let servings: Double
    let estimatedCalories: Int?
}

enum ReferenceObject: Hashable {
    case creditCard
    case coin
    case hand
    case cup

    var name: String {
        switch self {
        case .creditCard: return "Credit Card"
        case .coin: return "Coin"
        case .hand: return "Hand"
        case .cup: return "Cup"
        }
    }

    var icon: String {
        switch self {
        case .creditCard: return "creditcard.fill"
        case .coin: return "dollarsign.circle.fill"
        case .hand: return "hand.raised.fill"
        case .cup: return "cup.and.saucer.fill"
        }
    }

    var dimensions: SIMD3<Float> {
        switch self {
        case .creditCard: return SIMD3(0.086, 0.001, 0.054) // 86mm x 54mm
        case .coin: return SIMD3(0.024, 0.002, 0.024) // 24mm diameter
        case .hand: return SIMD3(0.09, 0.002, 0.18) // ~9cm x 18cm
        case .cup: return SIMD3(0.08, 0.1, 0.08) // 8cm diameter, 10cm height
        }
    }

    var size: String {
        switch self {
        case .creditCard: return "86×54mm"
        case .coin: return "Ø24mm"
        case .hand: return "~18cm"
        case .cup: return "Ø8cm"
        }
    }

    var realSize: Float {
        switch self {
        case .creditCard: return 0.086
        case .coin: return 0.024
        case .hand: return 0.18
        case .cup: return 0.08
        }
    }
}

struct ARPortionEstimatorView_Previews: PreviewProvider {
    static var previews: some View {
        ARPortionEstimatorView()
    }
}

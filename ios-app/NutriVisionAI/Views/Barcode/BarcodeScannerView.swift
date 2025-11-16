//
//  BarcodeScannerView.swift
//  NutriVision AI
//
//  Barcode scanner for packaged foods
//

import SwiftUI
import AVFoundation
import VisionKit

struct BarcodeScannerView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = BarcodeScannerViewModel()

    var body: some View {
        ZStack {
            // Camera preview
            BarcodeCameraView(viewModel: viewModel)
                .edgesIgnoringSafeArea(.all)

            // Overlay
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

                    if viewModel.isTorchAvailable {
                        Button(action: {
                            viewModel.toggleTorch()
                        }) {
                            Image(systemName: viewModel.isTorchOn ? "flashlight.on.fill" : "flashlight.off.fill")
                                .font(.title)
                                .foregroundColor(.white)
                                .shadow(radius: 3)
                        }
                    }
                }
                .padding()

                Spacer()

                // Scanning frame
                ScanningFrame()
                    .frame(width: 280, height: 280)

                Spacer()

                // Instructions
                VStack(spacing: 16) {
                    if viewModel.isScanning {
                        HStack(spacing: 8) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))

                            Text("Scanning...")
                                .foregroundColor(.white)
                        }
                    } else {
                        Text("Position barcode within the frame")
                            .foregroundColor(.white)
                            .padding(.horizontal, 40)
                            .multilineTextAlignment(.center)
                    }

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .sheet(item: $viewModel.scannedProduct) { product in
            ProductDetailView(product: product)
        }
        .onAppear {
            viewModel.startScanning()
        }
        .onDisappear {
            viewModel.stopScanning()
        }
    }
}

// MARK: - Scanning Frame

struct ScanningFrame: View {
    @State private var animationAmount: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Corner brackets
            Rectangle()
                .stroke(Color.green, lineWidth: 4)
                .frame(width: 280, height: 280)

            // Scanning line
            Rectangle()
                .fill(LinearGradient(
                    gradient: Gradient(colors: [.clear, .green, .clear]),
                    startPoint: .leading,
                    endPoint: .trailing
                ))
                .frame(height: 2)
                .offset(y: -140 + (280 * animationAmount))
                .onAppear {
                    withAnimation(
                        Animation.linear(duration: 2)
                            .repeatForever(autoreverses: false)
                    ) {
                        animationAmount = 1.0
                    }
                }
        }
    }
}

// MARK: - Camera View

struct BarcodeCameraView: UIViewRepresentable {
    @ObservedObject var viewModel: BarcodeScannerViewModel

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black

        if let previewLayer = viewModel.previewLayer {
            previewLayer.frame = view.bounds
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = viewModel.previewLayer {
            DispatchQueue.main.async {
                previewLayer.frame = uiView.bounds
            }
        }
    }
}

// MARK: - ViewModel

class BarcodeScannerViewModel: NSObject, ObservableObject {
    @Published var scannedProduct: ScannedProduct?
    @Published var isScanning = false
    @Published var errorMessage: String?
    @Published var isTorchOn = false
    @Published var isTorchAvailable = false

    private var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    private var lastScannedCode: String?
    private var lastScannedTime: Date?

    override init() {
        super.init()
        setupCamera()
    }

    private func setupCamera() {
        captureSession = AVCaptureSession()

        guard let captureSession = captureSession else { return }
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }

        isTorchAvailable = videoCaptureDevice.hasTorch

        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            errorMessage = "Camera access denied"
            return
        }

        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            errorMessage = "Could not add video input"
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [
                .ean8, .ean13, .pdf417, .upce, .code39, .code128
            ]
        } else {
            errorMessage = "Could not add metadata output"
            return
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    }

    func startScanning() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()

            DispatchQueue.main.async {
                self?.isScanning = true
            }
        }
    }

    func stopScanning() {
        captureSession?.stopRunning()
        isScanning = false

        if isTorchOn {
            toggleTorch()
        }
    }

    func toggleTorch() {
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch else { return }

        do {
            try device.lockForConfiguration()
            device.torchMode = isTorchOn ? .off : .on
            isTorchOn.toggle()
            device.unlockForConfiguration()
        } catch {
            print("Torch could not be used")
        }
    }

    private func handleScannedCode(_ code: String) {
        // Prevent duplicate scans within 3 seconds
        if let lastCode = lastScannedCode,
           let lastTime = lastScannedTime,
           lastCode == code,
           Date().timeIntervalSince(lastTime) < 3 {
            return
        }

        lastScannedCode = code
        lastScannedTime = Date()

        // Vibrate
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // Fetch product info
        Task {
            await fetchProductInfo(barcode: code)
        }
    }

    private func fetchProductInfo(barcode: String) async {
        // Call backend API to get product info
        do {
            let apiClient = APIClient.shared

            struct BarcodeRequest: Codable {
                let barcode: String
            }

            struct BarcodeResponse: Codable {
                let name: String
                let brand: String?
                let servingSize: String?
                let calories: Int
                let protein: Double
                let carbs: Double
                let fat: Double
                let fiber: Double?
                let sugar: Double?
                let sodium: Double?
                let imageUrl: String?
            }

            let response: BarcodeResponse = try await apiClient.request(
                endpoint: "\(Config.Endpoints.ai)/barcode",
                method: "POST",
                body: BarcodeRequest(barcode: barcode)
            )

            await MainActor.run {
                scannedProduct = ScannedProduct(
                    barcode: barcode,
                    name: response.name,
                    brand: response.brand,
                    servingSize: response.servingSize,
                    nutrition: Nutrition(
                        calories: response.calories,
                        protein: response.protein,
                        carbs: response.carbs,
                        fat: response.fat,
                        fiber: response.fiber,
                        sugar: response.sugar,
                        sodium: response.sodium,
                        cholesterol: nil
                    ),
                    imageUrl: response.imageUrl
                )
            }
        } catch {
            await MainActor.run {
                errorMessage = "Product not found. Try entering manually."
            }
        }
    }
}

// MARK: - Metadata Delegate

extension BarcodeScannerViewModel: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let metadataObject = metadataObjects.first,
              let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
              let stringValue = readableObject.stringValue else { return }

        handleScannedCode(stringValue)
    }
}

// MARK: - Scanned Product Model

struct ScannedProduct: Identifiable {
    let id = UUID()
    let barcode: String
    let name: String
    let brand: String?
    let servingSize: String?
    let nutrition: Nutrition
    let imageUrl: String?
}

// MARK: - Product Detail View

struct ProductDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    let product: ScannedProduct

    @State private var servings: Double = 1.0

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Product image
                    if let imageUrl = product.imageUrl {
                        AsyncImage(url: URL(string: imageUrl)) { image in
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 200)
                        }
                        .cornerRadius(12)
                    }

                    // Product info
                    VStack(alignment: .leading, spacing: 8) {
                        Text(product.name)
                            .font(.title2)
                            .fontWeight(.bold)

                        if let brand = product.brand {
                            Text(brand)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        if let servingSize = product.servingSize {
                            Text("Serving: \(servingSize)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Text("Barcode: \(product.barcode)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                    // Servings adjuster
                    VStack(spacing: 12) {
                        Text("Servings")
                            .font(.headline)

                        HStack {
                            Button(action: {
                                if servings > 0.5 {
                                    servings -= 0.5
                                }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.green)
                            }

                            Text(String(format: "%.1f", servings))
                                .font(.title2)
                                .fontWeight(.bold)
                                .frame(minWidth: 60)

                            Button(action: {
                                servings += 0.5
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Nutrition
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Nutrition Facts")
                            .font(.headline)

                        NutritionGrid(
                            nutrition: adjustedNutrition
                        )
                    }
                    .padding(.horizontal)

                    // Add to journal button
                    CustomButton(
                        title: "Add to Journal",
                        icon: "plus.circle.fill",
                        style: .primary
                    ) {
                        addToJournal()
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Product Info")
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

    private var adjustedNutrition: Nutrition {
        Nutrition(
            calories: Int(Double(product.nutrition.calories) * servings),
            protein: product.nutrition.protein * servings,
            carbs: product.nutrition.carbs * servings,
            fat: product.nutrition.fat * servings,
            fiber: product.nutrition.fiber.map { $0 * servings },
            sugar: product.nutrition.sugar.map { $0 * servings },
            sodium: product.nutrition.sodium.map { $0 * servings },
            cholesterol: product.nutrition.cholesterol.map { $0 * servings }
        )
    }

    private func addToJournal() {
        // Save to Apple Health
        Task {
            do {
                try await HealthKitManager.shared.saveMealToHealth(
                    calories: Double(adjustedNutrition.calories),
                    protein: adjustedNutrition.protein,
                    carbs: adjustedNutrition.carbs,
                    fat: adjustedNutrition.fat
                )
            } catch {
                print("Failed to save to Health: \(error)")
            }
        }

        presentationMode.wrappedValue.dismiss()
    }
}

struct BarcodeScannerView_Previews: PreviewProvider {
    static var previews: some View {
        BarcodeScannerView()
    }
}

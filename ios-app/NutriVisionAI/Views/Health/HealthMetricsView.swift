//
//  HealthMetricsView.swift
//  NutriVision AI
//
//  Track and visualize health metrics over time
//

import SwiftUI
import Charts

struct HealthMetricsView: View {
    @StateObject private var viewModel = HealthMetricsViewModel()
    @State private var selectedMetric: HealthMetric = .weight
    @State private var selectedTimeRange: TimeRange = .week

    enum HealthMetric: String, CaseIterable {
        case weight = "Weight"
        case calories = "Calories"
        case protein = "Protein"
        case carbs = "Carbs"
        case fat = "Fat"
        case water = "Water"

        var icon: String {
            switch self {
            case .weight: return "scalemass"
            case .calories: return "flame"
            case .protein: return "fork.knife"
            case .carbs: return "leaf"
            case .fat: return "drop"
            case .water: return "drop.fill"
            }
        }

        var color: Color {
            switch self {
            case .weight: return .blue
            case .calories: return .orange
            case .protein: return .red
            case .carbs: return .yellow
            case .fat: return .purple
            case .water: return .cyan
            }
        }
    }

    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case threeMonths = "3 Months"
        case year = "Year"
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Metric Selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(HealthMetric.allCases, id: \.self) { metric in
                                MetricButton(
                                    metric: metric,
                                    isSelected: selectedMetric == metric
                                ) {
                                    selectedMetric = metric
                                    Task {
                                        await viewModel.loadMetrics(
                                            metric: metric,
                                            timeRange: selectedTimeRange
                                        )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Time Range Selector
                    Picker("Time Range", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .onChange(of: selectedTimeRange) { newValue in
                        Task {
                            await viewModel.loadMetrics(
                                metric: selectedMetric,
                                timeRange: newValue
                            )
                        }
                    }

                    // Chart
                    if viewModel.isLoading {
                        ProgressView("Loading metrics...")
                            .frame(height: 300)
                    } else if let error = viewModel.errorMessage {
                        VStack {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundColor(.orange)
                            Text(error)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            Button("Retry") {
                                Task {
                                    await viewModel.loadMetrics(
                                        metric: selectedMetric,
                                        timeRange: selectedTimeRange
                                    )
                                }
                            }
                            .padding(.top)
                        }
                        .frame(height: 300)
                        .padding()
                    } else if !viewModel.dataPoints.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            // Current Value
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Current")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(viewModel.currentValue)
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(selectedMetric.color)
                                }

                                Spacer()

                                // Change Indicator
                                if let change = viewModel.changePercentage {
                                    VStack(alignment: .trailing) {
                                        Text("Change")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        HStack(spacing: 4) {
                                            Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                                            Text(String(format: "%.1f%%", abs(change)))
                                        }
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(change >= 0 ? .green : .red)
                                    }
                                }
                            }
                            .padding(.horizontal)

                            // Line Chart
                            Chart {
                                ForEach(viewModel.dataPoints) { point in
                                    LineMark(
                                        x: .value("Date", point.date),
                                        y: .value("Value", point.value)
                                    )
                                    .foregroundStyle(selectedMetric.color.gradient)
                                    .interpolationMethod(.catmullRom)

                                    AreaMark(
                                        x: .value("Date", point.date),
                                        y: .value("Value", point.value)
                                    )
                                    .foregroundStyle(
                                        selectedMetric.color.opacity(0.2).gradient
                                    )
                                    .interpolationMethod(.catmullRom)
                                }
                            }
                            .frame(height: 250)
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                            Text("No data available")
                                .foregroundColor(.secondary)
                            Text("Start logging your metrics to see trends")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(height: 300)
                        .padding()
                    }

                    // Statistics
                    if !viewModel.dataPoints.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Statistics")
                                .font(.headline)
                                .padding(.horizontal)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                StatCard(title: "Average", value: viewModel.averageValue, color: .blue)
                                StatCard(title: "Highest", value: viewModel.highestValue, color: .green)
                                StatCard(title: "Lowest", value: viewModel.lowestValue, color: .orange)
                                StatCard(title: "Total Days", value: "\(viewModel.dataPoints.count)", color: .purple)
                            }
                            .padding(.horizontal)
                        }
                    }

                    Spacer()
                }
                .padding(.vertical)
            }
            .navigationTitle("Health Metrics")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await viewModel.loadMetrics(
                    metric: selectedMetric,
                    timeRange: selectedTimeRange
                )
            }
        }
    }
}

// MARK: - Metric Button

struct MetricButton: View {
    let metric: HealthMetricsView.HealthMetric
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: metric.icon)
                    .font(.title2)
                Text(metric.rawValue)
                    .font(.caption)
            }
            .frame(width: 80, height: 80)
            .background(isSelected ? metric.color.opacity(0.2) : Color.gray.opacity(0.1))
            .foregroundColor(isSelected ? metric.color : .primary)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? metric.color : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - ViewModel

@MainActor
class HealthMetricsViewModel: ObservableObject {
    @Published var dataPoints: [MetricDataPoint] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    var currentValue: String {
        guard let latest = dataPoints.last else { return "—" }
        return String(format: "%.1f", latest.value)
    }

    var averageValue: String {
        guard !dataPoints.isEmpty else { return "—" }
        let avg = dataPoints.map { $0.value }.reduce(0, +) / Double(dataPoints.count)
        return String(format: "%.1f", avg)
    }

    var highestValue: String {
        guard let max = dataPoints.map({ $0.value }).max() else { return "—" }
        return String(format: "%.1f", max)
    }

    var lowestValue: String {
        guard let min = dataPoints.map({ $0.value }).min() else { return "—" }
        return String(format: "%.1f", min)
    }

    var changePercentage: Double? {
        guard dataPoints.count >= 2,
              let first = dataPoints.first,
              let last = dataPoints.last,
              first.value > 0 else { return nil }
        return ((last.value - first.value) / first.value) * 100
    }

    func loadMetrics(metric: HealthMetricsView.HealthMetric, timeRange: HealthMetricsView.TimeRange) async {
        isLoading = true
        errorMessage = nil

        // Simulate API call with mock data
        try? await Task.sleep(nanoseconds: 500_000_000)

        // Generate mock data
        let days = daysForTimeRange(timeRange)
        var mockData: [MetricDataPoint] = []

        for i in 0..<days {
            let date = Calendar.current.date(byAdding: .day, value: -days + i, to: Date())!
            let baseValue = baseValueForMetric(metric)
            let variance = Double.random(in: -10...10)
            let value = baseValue + variance

            mockData.append(MetricDataPoint(
                id: UUID().uuidString,
                date: date,
                value: value
            ))
        }

        dataPoints = mockData
        isLoading = false
    }

    private func daysForTimeRange(_ range: HealthMetricsView.TimeRange) -> Int {
        switch range {
        case .week: return 7
        case .month: return 30
        case .threeMonths: return 90
        case .year: return 365
        }
    }

    private func baseValueForMetric(_ metric: HealthMetricsView.HealthMetric) -> Double {
        switch metric {
        case .weight: return 70.0
        case .calories: return 2000.0
        case .protein: return 80.0
        case .carbs: return 200.0
        case .fat: return 60.0
        case .water: return 2.5
        }
    }
}

// MARK: - Models

struct MetricDataPoint: Identifiable {
    let id: String
    let date: Date
    let value: Double
}

// MARK: - Preview

struct HealthMetricsView_Previews: PreviewProvider {
    static var previews: some View {
        HealthMetricsView()
    }
}

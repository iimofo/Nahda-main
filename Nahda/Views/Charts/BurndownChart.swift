import SwiftUI
import Charts

struct BurndownChartData: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let tasks: Double
    let isIdeal: Bool
    let velocity: Double
    let efficiency: Double
    
    static func == (lhs: BurndownChartData, rhs: BurndownChartData) -> Bool {
        lhs.date == rhs.date &&
        lhs.tasks == rhs.tasks &&
        lhs.isIdeal == rhs.isIdeal &&
        lhs.velocity == rhs.velocity &&
        lhs.efficiency == rhs.efficiency
    }
}

struct BurndownChart: View {
    let tasks: [Task]
    let startDate: Date
    let endDate: Date
    @State private var selectedPoint: BurndownChartData?
    @State private var highlightedDate: Date?
    @State private var chartType: ChartType = .burndown
    
    enum ChartType {
        case burndown
        case velocity
        case efficiency
    }
    
    private var chartData: [BurndownChartData] {
        var data: [BurndownChartData] = []
        let totalTasks = Double(tasks.count)
        
        // Calculate ideal burndown
        let duration = endDate.timeIntervalSince(startDate)
        let dailyBurn = totalTasks / (duration / (24 * 3600))
        
        var currentDate = startDate
        var remainingTasks = totalTasks
        
        while currentDate <= endDate {
            let completedToDate = tasks.filter { 
                $0.completedAt?.timeIntervalSince(startDate) ?? 0 <= currentDate.timeIntervalSince(startDate)
            }
            
            let velocity = calculateVelocity(for: completedToDate, at: currentDate)
            let efficiency = calculateEfficiency(for: completedToDate)
            
            data.append(BurndownChartData(
                date: currentDate,
                tasks: remainingTasks,
                isIdeal: true,
                velocity: velocity,
                efficiency: efficiency
            ))
            
            remainingTasks -= dailyBurn
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        // Add actual burndown data
        let sortedCompletions = tasks.compactMap { $0.completedAt }.sorted()
        var actualTasks = totalTasks
        
        data.append(BurndownChartData(
            date: startDate,
            tasks: actualTasks,
            isIdeal: false,
            velocity: 0,
            efficiency: 1
        ))
        
        for date in sortedCompletions {
            actualTasks -= 1
            let completedToDate = tasks.filter { $0.completedAt ?? Date() <= date }
            let velocity = calculateVelocity(for: completedToDate, at: date)
            let efficiency = calculateEfficiency(for: completedToDate)
            
            data.append(BurndownChartData(
                date: date,
                tasks: actualTasks,
                isIdeal: false,
                velocity: velocity,
                efficiency: efficiency
            ))
        }
        
        return data
    }
    
    private func calculateVelocity(for tasks: [Task], at date: Date) -> Double {
        let weekInterval = 7 * 24 * 3600.0
        let periodStart = date.addingTimeInterval(-weekInterval)
        let tasksInPeriod = tasks.filter { 
            ($0.completedAt ?? Date()) > periodStart && ($0.completedAt ?? Date()) <= date
        }
        return Double(tasksInPeriod.count) / 7.0  // Tasks per day
    }
    
    private func calculateEfficiency(for tasks: [Task]) -> Double {
        guard !tasks.isEmpty else { return 1.0 }
        let onTime = tasks.filter { task in
            guard let dueDate = task.dueDate, let completedAt = task.completedAt else { return false }
            return completedAt <= dueDate
        }
        return Double(onTime.count) / Double(tasks.count)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Chart Type Picker
            Picker("Chart Type", selection: $chartType) {
                Text("Burndown").tag(ChartType.burndown)
                Text("Velocity").tag(ChartType.velocity)
                Text("Efficiency").tag(ChartType.efficiency)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            // Main Chart
            VStack {
                Text(chartTitle)
                    .font(.headline)
                
                Chart(chartData) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value(yAxisLabel, yValue(for: point))
                    )
                    .foregroundStyle(point.isIdeal ? .gray : .blue)
                    .lineStyle(point.isIdeal ? StrokeStyle(dash: [5]) : StrokeStyle())
                    
                    // Add points for actual data
                    if !point.isIdeal {
                        PointMark(
                            x: .value("Date", point.date),
                            y: .value(yAxisLabel, yValue(for: point))
                        )
                        .foregroundStyle(.blue)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(date.formatted(.dateTime.day()))
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .frame(height: 200)
                .chartOverlay { proxy in
                    GeometryReader { geometry in
                        Rectangle().fill(.clear).contentShape(Rectangle())
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        let x = value.location.x - geometry.frame(in: .local).origin.x
                                        guard let date = proxy.value(atX: x) as Date? else { return }
                                        highlightedDate = date
                                        selectedPoint = findNearestPoint(to: date)
                                    }
                                    .onEnded { _ in
                                        highlightedDate = nil
                                        selectedPoint = nil
                                    }
                            )
                    }
                }
            }
            
            // Legend
            ChartLegend(chartType: chartType)
            
            // Tooltip
            if let selectedPoint = selectedPoint {
                TooltipView(point: selectedPoint, chartType: chartType)
                    .transition(.opacity)
                    .animation(.easeInOut, value: selectedPoint)
            }
            
            // Additional Stats
            HStack(spacing: 20) {
                StatBox(
                    title: "Average Velocity",
                    value: String(format: "%.1f tasks/day", 
                        chartData.filter { !$0.isIdeal }.map(\.velocity).reduce(0, +) / 
                        Double(chartData.filter { !$0.isIdeal }.count)
                    ),
                    color: .blue
                )
                
                StatBox(
                    title: "Overall Efficiency",
                    value: String(format: "%.0f%%", 
                        chartData.filter { !$0.isIdeal }.map(\.efficiency).reduce(0, +) / 
                        Double(chartData.filter { !$0.isIdeal }.count) * 100
                    ),
                    color: .green
                )
            }
            .padding(.horizontal)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(15)
    }
    
    private var chartTitle: String {
        switch chartType {
        case .burndown: return "Burndown Chart"
        case .velocity: return "Velocity Trend"
        case .efficiency: return "Efficiency Trend"
        }
    }
    
    private var yAxisLabel: String {
        switch chartType {
        case .burndown: return "Tasks Remaining"
        case .velocity: return "Tasks/Day"
        case .efficiency: return "Efficiency"
        }
    }
    
    private func yValue(for point: BurndownChartData) -> Double {
        switch chartType {
        case .burndown: return point.tasks
        case .velocity: return point.velocity
        case .efficiency: return point.efficiency
        }
    }
    
    private func findNearestPoint(to date: Date) -> BurndownChartData? {
        return chartData.min { a, b in
            abs(a.date.timeIntervalSince(date)) < abs(b.date.timeIntervalSince(date))
        }
    }
}

struct TooltipView: View {
    let point: BurndownChartData
    let chartType: BurndownChart.ChartType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(point.date.formatted(date: .abbreviated, time: .omitted))
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Circle()
                    .fill(point.isIdeal ? .gray : .blue)
                    .frame(width: 8, height: 8)
                
                switch chartType {
                case .burndown:
                    Text("\(Int(point.tasks)) tasks remaining")
                case .velocity:
                    Text("\(point.velocity, specifier: "%.1f") tasks/day")
                case .efficiency:
                    Text("\(point.efficiency * 100, specifier: "%.0f")% efficient")
                }
            }
            
            if !point.isIdeal {
                Text("Velocity: \(point.velocity, specifier: "%.1f") tasks/day")
                Text("Efficiency: \(point.efficiency * 100, specifier: "%.0f")%")
            }
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 4)
    }
}

struct ChartLegend: View {
    let chartType: BurndownChart.ChartType
    
    var body: some View {
        HStack(spacing: 20) {
            LegendItem(color: .gray, style: .dashed, label: "Ideal")
            LegendItem(color: .blue, style: .solid, label: "Actual")
        }
        .padding(.top, 8)
    }
}

struct LegendItem: View {
    let color: Color
    let style: LineStyle
    let label: String
    
    enum LineStyle {
        case solid, dashed
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Path { path in
                path.move(to: CGPoint(x: 0, y: 8))
                path.addLine(to: CGPoint(x: 16, y: 8))
            }
            .stroke(color, style: style == .dashed ? StrokeStyle(dash: [5]) : StrokeStyle())
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// Preview provider for testing
#Preview {
    BurndownChart(
        tasks: [],
        startDate: Date(),
        endDate: Date().addingTimeInterval(7 * 24 * 3600)
    )
} 

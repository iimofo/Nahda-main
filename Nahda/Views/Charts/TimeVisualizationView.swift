import SwiftUI
import Charts

struct TimeVisualizationView: View {
    let tasks: [Task]
    let analytics: TimeAnalytics
    
    var body: some View {
        VStack(spacing: 20) {
            // Completion Time Distribution
            Chart {
                ForEach(TaskPriority.allCases, id: \.self) { priority in
                    let avgTime = analytics.completionTimesByPriority[priority] ?? 0
                    BarMark(
                        x: .value("Priority", priority.rawValue.capitalized),
                        y: .value("Time", avgTime / 3600) // Convert to hours
                    )
                    .foregroundStyle(priority.color)
                }
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let hours = value.as(Double.self) {
                            Text("\(Int(hours))h")
                        }
                    }
                }
            }
            
            // Performance Trend
            HStack {
                VStack(alignment: .leading) {
                    Text("Performance Trend")
                        .font(.headline)
                    
                    HStack {
                        Image(systemName: analytics.getCompletionTrend().icon)
                        Text(analytics.getCompletionTrend().description)
                    }
                    .foregroundColor(analytics.getCompletionTrend().color)
                }
                
                Spacer()
                
                CircularProgressView(
                    progress: calculateEfficiency(),
                    color: analytics.getCompletionTrend().color
                )
                .frame(width: 60, height: 60)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(15)
            
            // Predictions
            if let nextTask = tasks.first(where: { !$0.isCompleted }) {
                PredictionCard(
                    task: nextTask,
                    estimatedTime: analytics.estimateCompletionTime(for: nextTask)
                )
            }
        }
    }
    
    private func calculateEfficiency() -> Double {
        let completedTasks = tasks.filter { $0.isCompleted && $0.finishTime != nil }
        let avgTime = analytics.averageCompletionTime
        
        return completedTasks.reduce(0.0) { total, task in
            total + (task.finishTime ?? avgTime > avgTime ? 0 : 1)
        } / Double(max(1, completedTasks.count))
    }
}

struct PredictionCard: View {
    let task: Task
    let estimatedTime: TimeInterval
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Next Task Prediction")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(task.title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Image(systemName: "clock.fill")
                    Text("Estimated: \(formatTime(estimatedTime))")
                }
                .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(15)
    }
    
    private func formatTime(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
}

struct CircularProgressView: View {
    let progress: Double
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 8)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut, value: progress)
            
            Text("\(Int(progress * 100))%")
                .font(.caption)
                .bold()
        }
    }
} 
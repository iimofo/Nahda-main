import SwiftUI

struct CompletionRateChart: View {
    let tasks: [Task]
    
    private var completionRate: Double {
        guard !tasks.isEmpty else { return 0 }
        let completed = Double(tasks.filter { $0.isCompleted }.count)
        return (completed / Double(tasks.count)) * 100
    }
    
    var body: some View {
        VStack {
            Text("\(Int(completionRate))%")
                .font(.title)
                .bold()
            
            Text("Tasks Completed")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
} 

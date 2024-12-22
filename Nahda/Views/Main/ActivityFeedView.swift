import SwiftUI

struct ActivityFeedView: View {
    let team: Team
    @StateObject private var taskViewModel = TaskViewModel()
    @State private var activities: [TaskActivity] = []
    @State private var isLoading = true
    
    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView("Loading activities...")
                    .padding(.top, 50)
            } else if activities.isEmpty {
                EmptyActivityView()
            } else {
                LazyVStack(spacing: 15) {
                    ForEach(activities) { activity in
                        ActivityCard(activity: activity)
                    }
                }
                .padding()
            }
        }
        .refreshable {
            await loadActivities()
        }
        .onAppear {
            loadActivitiesNonAsync()
        }
    }
    
    private func loadActivitiesNonAsync() {
        isLoading = true
        taskViewModel.fetchActivities(for: team.id ?? "") { fetchedActivities in
            DispatchQueue.main.async {
                self.activities = fetchedActivities
                self.isLoading = false
            }
        }
    }
    
    private func loadActivities() async {
        isLoading = true
        var hasResumed = false
        
        await withCheckedContinuation { continuation in
            taskViewModel.fetchActivities(for: team.id ?? "") { fetchedActivities in
                DispatchQueue.main.async {
                    self.activities = fetchedActivities
                    self.isLoading = false
                    
                    // Only resume once
                    if !hasResumed {
                        hasResumed = true
                        continuation.resume()
                    }
                }
            }
        }
    }
}

struct ActivityCard: View {
    let activity: TaskActivity
    @State private var showDetails = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                ActivityIcon(type: activity.action)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(activity.action.displayTitle)
                        .font(.headline)
                    
                    Text(activity.timestamp.timeAgoDisplay())
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button {
                    withAnimation {
                        showDetails.toggle()
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .rotationEffect(.degrees(showDetails ? 90 : 0))
                        .foregroundColor(.gray)
                }
            }
            
            // Details
            if showDetails, let details = activity.details {
                Text(details)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct ActivityIcon: View {
    let type: TaskActivityType
    
    var body: some View {
        Image(systemName: type.iconName)
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(width: 32, height: 32)
            .background(type.color)
            .cornerRadius(8)
    }
}

struct EmptyActivityView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Activity Yet")
                .font(.headline)
            
            Text("Team activities will appear here")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(15)
        .padding()
    }
}

// Extensions to support the activity feed
extension TaskActivityType {
    var displayTitle: String {
        switch self {
        case .created: return "Task Created"
        case .updated: return "Task Updated"
        case .statusChanged: return "Status Changed"
        case .commented: return "New Comment"
        case .mentioned: return "Mentioned in Task"
        case .dependencyAdded: return "Dependency Added"
        case .dependencyRemoved: return "Dependency Removed"
        case .priorityChanged: return "Priority Changed"
        case .dueDateChanged: return "Due Date Changed"
        }
    }
    
    var iconName: String {
        switch self {
        case .created: return "plus.circle.fill"
        case .updated: return "pencil.circle.fill"
        case .statusChanged: return "checkmark.circle.fill"
        case .commented: return "message.circle.fill"
        case .mentioned: return "at.circle.fill"
        case .dependencyAdded: return "link.circle.fill"
        case .dependencyRemoved: return "link.badge.plus"
        case .priorityChanged: return "flag.circle.fill"
        case .dueDateChanged: return "calendar.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .created: return .green
        case .updated: return .blue
        case .statusChanged: return .purple
        case .commented: return .orange
        case .mentioned: return .pink
        case .dependencyAdded, .dependencyRemoved: return .indigo
        case .priorityChanged: return .red
        case .dueDateChanged: return .teal
        }
    }
}

extension Date {
    func timeAgoDisplay() -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day], from: self, to: now)
        
        if let day = components.day, day > 0 {
            return day == 1 ? "Yesterday" : "\(day) days ago"
        } else if let hour = components.hour, hour > 0 {
            return "\(hour) hour\(hour == 1 ? "" : "s") ago"
        } else if let minute = components.minute, minute > 0 {
            return "\(minute) minute\(minute == 1 ? "" : "s") ago"
        } else {
            return "Just now"
        }
    }
} 

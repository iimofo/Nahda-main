import SwiftUI

struct UserActivityView: View {
    let userId: String
    @StateObject private var userViewModel = UserViewModel()
    
    var body: some View {
        List(userViewModel.getActivities(for: userId)) { activity in
            ActivityRow(activity: activity)
        }
        .onAppear {
            userViewModel.startListeningToActivity(for: userId)
        }
        .onDisappear {
            userViewModel.stopListeningToActivity(for: userId)
        }
    }
}

struct ActivityRow: View {
    let activity: UserActivity
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconName(for: activity.type))
                    .foregroundColor(iconColor(for: activity.type))
                Text(activity.type.rawValue.capitalized)
                    .font(.headline)
                Spacer()
                Text(formatDate(activity.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(activity.details)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func iconName(for type: UserActivity.ActivityType) -> String {
        switch type {
        case .login: return "person.badge.key.fill"
        case .logout: return "person.badge.minus"
        case .taskCreated: return "plus.square.fill"
        case .taskCompleted: return "checkmark.square.fill"
        case .taskAssigned: return "person.badge.clock.fill"
        case .teamJoined: return "person.3.fill"
        case .teamCreated: return "person.3.sequence.fill"
        case .commentAdded: return "message.fill"
        }
    }
    
    private func iconColor(for type: UserActivity.ActivityType) -> Color {
        switch type {
        case .login, .logout: return .blue
        case .taskCreated: return .green
        case .taskCompleted: return .purple
        case .taskAssigned: return .orange
        case .teamJoined, .teamCreated: return .indigo
        case .commentAdded: return .cyan
        }
    }
} 
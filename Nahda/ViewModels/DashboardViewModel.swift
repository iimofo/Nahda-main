import SwiftUI
import FirebaseFirestore

class DashboardViewModel: ObservableObject {
    @Published var teamAnalytics: [String: TeamAnalytics] = [:]
    @Published var teamActivities: [String: [TeamActivity]] = [:]
    @Published var isLoading = true
    @Published var showError = false
    @Published var errorMessage: String?
} 
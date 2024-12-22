import SwiftUI

struct SubTeamPermissionsView: View {
    let team: Team
    @State private var permissions: [SubTeamPermission] = []
    
    struct SubTeamPermission: Identifiable {
        let id = UUID()
        var canInviteMembers: Bool
        var canRemoveMembers: Bool
        var canCreateTasks: Bool
        var canDeleteTasks: Bool
        var canModifyTasks: Bool
    }
    
    var body: some View {
        Form {
            Section("Member Permissions") {
                Toggle("Can invite members", isOn: .constant(true))
                Toggle("Can remove members", isOn: .constant(false))
            }
            
            Section("Task Permissions") {
                Toggle("Can create tasks", isOn: .constant(true))
                Toggle("Can delete tasks", isOn: .constant(false))
                Toggle("Can modify tasks", isOn: .constant(true))
            }
            
            Section("Task Visibility") {
                Toggle("Can view parent team tasks", isOn: .constant(true))
                Toggle("Can view other subteam tasks", isOn: .constant(false))
            }
            
            Section {
                Button("Save Changes") {
                    // Save permissions
                }
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Subteam Permissions")
    }
} 
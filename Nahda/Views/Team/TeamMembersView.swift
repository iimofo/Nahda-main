import SwiftUI

struct TeamMembersView: View {
    let team: Team
    let members: [User]
    let isTeamLeader: Bool
    let onRemoveMember: (User) -> Void
    let onAppear: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Group {
                if members.isEmpty {
                    ContentUnavailableView(
                        "No Team Members",
                        systemImage: "person.2.slash",
                        description: Text("This team currently has no members")
                    )
                } else {
                    List {
                        Section(header: Text("\(members.count) Members")) {
                            ForEach(members) { member in
                                MemberRow(
                                    member: member,
                                    isLeader: member.id == team.leaderId,
                                    isTeamLeader: isTeamLeader,
                                    onRemove: {
                                        onRemoveMember(member)
                                        if members.count == 1 {
                                            dismiss()
                                        }
                                    }
                                )
                            }
                        }
                    }
                }
            }
            .navigationTitle("Team Members")
            .navigationBarItems(
                trailing: Button("Done") {
                    dismiss()
                }
            )
            .task {
                onAppear()
            }
            .refreshable {
                onAppear()
            }
        }
    }
}

struct MemberRow: View {
    let member: User
    let isLeader: Bool
    let isTeamLeader: Bool
    let onRemove: () -> Void
    @State private var showRemoveAlert = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Member Avatar
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(member.name.prefix(1).uppercased())
                        .font(.headline)
                        .foregroundColor(.gray)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(member.name)
                        .font(.headline)
                    
                    if isLeader {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                    }
                }
                
                Text(member.email)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            if isTeamLeader && !isLeader {
                Button {
                    showRemoveAlert = true
                } label: {
                    Image(systemName: "person.fill.xmark")
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.vertical, 8)
        .alert("Remove Member", isPresented: $showRemoveAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                onRemove()
            }
        } message: {
            Text("Are you sure you want to remove \(member.name) from the team?")
        }
    }
} 

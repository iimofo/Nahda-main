//
//  CreateTaskView.swift
//  Nahda
//
//  Created by mofo on 01.12.2024.
//
// CreateTaskView.swift
import SwiftUI
import FirebaseFirestore

struct CreateTaskView: View {
    var team: Team
    @Environment(\.presentationMode) var presentationMode
    @StateObject var taskViewModel = TaskViewModel()
    @State private var title = ""
    @State private var description = ""
    @State private var assignedToId = ""
    @State private var errorMessage: String?
    @State private var teamMembers = [User]()
    @State private var isLoading = true
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var isRefreshing = false
    @State private var priority: TaskPriority = .medium
    @State private var dueDate: Date? = nil
    
    var body: some View {
        NavigationView {
            ScrollView {
                if isLoading {
                    LoadingView()
                } else {
                    VStack(spacing: 20) {
                        // Task Info Section
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "Task Details", icon: "square.and.pencil")
                            
                            CustomTextField(
                                title: "Title",
                                text: $title,
                                icon: "pencil.line",
                                placeholder: "Enter task title"
                            )
                            
                            CustomTextField(
                                title: "Description",
                                text: $description,
                                icon: "text.alignleft",
                                placeholder: "Enter task description",
                                isMultiline: true
                            )
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(15)
                        
                        // Priority & Due Date Section
                        VStack(alignment: .leading, spacing: 15) {
                            HStack{
                                SectionHeader(title: "Priority & Timing", icon: "flag.fill")
                                Spacer()
                            }
//                                .padding(.leading)
                            
                            // Priority Selector
                            PrioritySelector(priority: $priority)
                            
                            // Due Date Selector
                            DueDateSelector(dueDate: $dueDate)
                        }
                        
                        .padding()
                        .frame(width: 420)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(15)
                        
                        // Member Selection Section
                        VStack(alignment: .leading, spacing: 15) {
                            SectionHeader(title: "Assign Task", icon: "person.2.fill")
                            
                            EnhancedMemberSelection(
                                selectedMemberId: $assignedToId,
                                teamMembers: teamMembers
                            )
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(15)
                        
                        if let errorMessage = errorMessage {
                            ErrorBanner(message: errorMessage)
                        }
                    }
                    .padding()
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Create Task")
            .navigationBarItems(
                leading: CancelButton(action: { presentationMode.wrappedValue.dismiss() }),
                trailing: CreateButton(action: createTask, isValid: isFormValid)
            )
        }
        .onAppear {
            fetchTeamMembers()
        }
    }
    
    private var isFormValid: Bool {
        !title.isEmpty && !description.isEmpty && !assignedToId.isEmpty
    }
    
    private func createTask() {
        guard let teamId = team.id else { return }
        
        let task = Task(
            teamId: teamId,
            title: title,
            description: description,
            assignedToId: assignedToId,
            priority: priority,
            dueDate: dueDate,
            startedAt: Date()
        )
        
        taskViewModel.createTask(task: task) { success, error in
            if success {
                presentationMode.wrappedValue.dismiss()
            } else {
                errorMessage = error
            }
        }
    }
    
    private func fetchTeamMembers(completion: @escaping () -> Void = {}) {
        let db = Firestore.firestore()
        let userIds = team.memberIds
        
        teamMembers = []
        let dispatchGroup = DispatchGroup()
        
        for userId in userIds {
            dispatchGroup.enter()
            db.collection("users").document(userId).getDocument { snapshot, error in
                defer { dispatchGroup.leave() }
                if let user = try? snapshot?.data(as: User.self) {
                    DispatchQueue.main.async {
                        teamMembers.append(user)
                    }
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            teamMembers.sort { $0.name < $1.name }
            isLoading = false
            completion()
        }
    }
    
    private func refreshData() async {
        isRefreshing = true
        
        await withCheckedContinuation { continuation in
            fetchTeamMembers(completion: {
                isRefreshing = false
                continuation.resume()
            })
        }
    }
}

// Supporting Views

struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text(title)
                .font(.headline)
        }
        .padding(.bottom, 8)
//        .padding(.leading, 2)
    }
}

struct PrioritySelector: View {
    @Binding var priority: TaskPriority
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Priority")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                ForEach(TaskPriority.allCases, id: \.self) { p in
                    PriorityButton(
                        priority: p,
                        isSelected: priority == p,
                        action: { priority = p }
                    )
                }
            }
        }
    }
}

struct PriorityButton: View {
    let priority: TaskPriority
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Circle()
                    .fill(priority.color)
                    .frame(width: 12, height: 12)
                Text(priority.rawValue.capitalized)
                    .font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? priority.color.opacity(0.15) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? priority.color : Color.gray.opacity(0.3))
                    )
            )
        }
        .foregroundColor(isSelected ? priority.color : .primary)
    }
}

struct DueDateSelector: View {
    @Binding var dueDate: Date?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Due Date")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if let date = dueDate {
                HStack {
                    DatePicker(
                        "Due Date",
                        selection: Binding(
                            get: { date },
                            set: { dueDate = $0 }
                        ),
                        in: Date()...,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.compact)
                    
                    Button(action: { dueDate = nil }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            } else {
                Button(action: {
                    dueDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
                }) {
                    HStack {
                        Image(systemName: "calendar.badge.plus")
                        Text("Add Due Date")
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }
}

struct EnhancedMemberSelection: View {
    @Binding var selectedMemberId: String
    let teamMembers: [User]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                ForEach(teamMembers) { member in
                    EnhancedMemberCard(
                        member: member,
                        isSelected: selectedMemberId == member.id,
                        action: { selectedMemberId = member.id ?? "" }
                    )
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

struct EnhancedMemberCard: View {
    let member: User
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Circle()
                    .fill(isSelected ? Color.blue : Color.gray.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(member.name.prefix(1).uppercased())
                            .font(.title3.bold())
                            .foregroundColor(isSelected ? .white : .primary)
                    )
                    .shadow(color: isSelected ? .blue.opacity(0.3) : .clear, radius: 5)
                
                Text(member.name)
                    .font(.caption)
                    .foregroundColor(isSelected ? .blue : .primary)
                    .lineLimit(1)
            }
            .frame(width: 70)
            .padding(.vertical, 8)
            .animation(.spring(), value: isSelected)
        }
    }
}

struct CustomTextField: View {
    let title: String
    @Binding var text: String
    let icon: String
    let placeholder: String
    var isMultiline: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.gray)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            if isMultiline {
                TextEditor(text: $text)
                    .frame(height: 100)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            } else {
                TextField(placeholder, text: $text)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
        }
    }
}

//struct LoadingView: View {
//    var body: some View {
//        VStack {
//            ProgressView()
//            Text("Loading team members...")
//                .foregroundColor(.gray)
//                .padding(.top)
//        }
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
//        .padding(.top, 100)
//    }
//}

struct ErrorBanner: View {
    let message: String
    
    var body: some View {
        Text(message)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.red)
            .cornerRadius(10)
    }
}

struct CancelButton: View {
    let action: () -> Void
    
    var body: some View {
        Button("Cancel", action: action)
    }
}

struct CreateButton: View {
    let action: () -> Void
    let isValid: Bool
    
    var body: some View {
        Button(action: action) {
            Text("Create")
                .bold()
        }
        .disabled(!isValid)
    }
}

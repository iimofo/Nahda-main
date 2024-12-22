//
//  InviteMemberView.swift
//  Nahda
//
//  Created by mofo on 01.12.2024.
//
import SwiftUI
import FirebaseFirestore

struct InviteMemberView: View {
    var team: Team
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var email = ""
    @State private var errorMessage: String?
    @State private var isLoading = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("Enter user's email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }

                Button(action: inviteMember) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("Invite")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .background(Color.blue)
                .cornerRadius(8)
                .disabled(isLoading)

                Spacer()
            }
            .padding()
            .navigationTitle("Invite Member")
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }

    func inviteMember() {
        guard !email.isEmpty else {
            errorMessage = "Please enter an email."
            return
        }

        isLoading = true
        errorMessage = nil

        let db = Firestore.firestore()
        db.collection("users")
            .whereField("email", isEqualTo: email.lowercased())
            .getDocuments { snapshot, error in
                isLoading = false
                if let error = error {
                    errorMessage = "Error fetching user: \(error.localizedDescription)"
                    return
                }

                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    errorMessage = "User not found."
                    return
                }

                if let user = try? documents.first?.data(as: User.self), let userId = user.id {
                    addUserToTeam(userId: userId)
                } else {
                    errorMessage = "Failed to parse user data."
                }
            }
    }

    func addUserToTeam(userId: String) {
        if team.memberIds.contains(userId) {
            errorMessage = "User is already a team member."
            return
        }

        let db = Firestore.firestore()
        let batch = db.batch()

        let teamRef = db.collection("teams").document(team.id!)
        batch.updateData(["memberIds": FieldValue.arrayUnion([userId])], forDocument: teamRef)

        let userRef = db.collection("users").document(userId)
        batch.updateData(["teamIds": FieldValue.arrayUnion([team.id!])], forDocument: userRef)

        batch.commit { error in
            if let error = error {
                errorMessage = "Error adding user to team: \(error.localizedDescription)"
            } else {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

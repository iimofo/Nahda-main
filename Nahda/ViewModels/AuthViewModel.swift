//
//  AuthViewModel.swift
//  Nahda
//
//  Created by mofo on 01.12.2024.
//
// AuthViewModel.swift

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Firebase


class AuthViewModel: ObservableObject {
    @Published var userSession: FirebaseAuth.User?
    @Published var currentUser: User?
    private var userListener: ListenerRegistration?

    init() {
        userSession = Auth.auth().currentUser
        if userSession != nil {
            fetchUser()
        }
    }

    func listenToUserChanges() {
        guard let uid = userSession?.uid else { return }
        let userRef = Firestore.firestore().collection("users").document(uid)
        userListener = userRef.addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error listening to user document: \(error.localizedDescription)")
                return
            }
            guard let snapshot = snapshot else { return }
            do {
                let user = try snapshot.data(as: User.self)
                DispatchQueue.main.async {
                    self.currentUser = user
                }
            } catch {
                print("Error decoding user: \(error)")
            }
        }
    }

    func signOut() {
        try? Auth.auth().signOut()
        self.userSession = nil
        self.currentUser = nil
        userListener?.remove()
    }

    // Make sure to call listenToUserChanges() after login or registration
    func login(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            // ... existing code ...
            self.userSession = result?.user
            self.listenToUserChanges()
            completion(true, nil)
        }
    }

    func register(name: String, email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(false, error.localizedDescription)
                return
            }
            guard let user = result?.user else {
                completion(false, "User data is nil.")
                return
            }
            self.userSession = user  // Set user session here where 'user' is in scope
            let userData = User(id: user.uid, name: name, email: email, teamIds: [])
            do {
                try Firestore.firestore().collection("users").document(user.uid).setData(from: userData) { error in
                    if let error = error {
                        completion(false, error.localizedDescription)
                    } else {
                        self.fetchUser()
                        completion(true, nil)
                    }
                }
            } catch {
                completion(false, error.localizedDescription)
            }
        }
    }
    
    func fetchUser() {
        guard let uid = userSession?.uid else { return }
        let userRef = Firestore.firestore().collection("users").document(uid)
        userRef.getDocument { snapshot, error in
            if let error = error {
                print("Error fetching user document: \(error.localizedDescription)")
                return
            }
            guard let snapshot = snapshot else {
                print("User snapshot is nil.")
                return
            }
            do {
                let user = try snapshot.data(as: User.self)
                DispatchQueue.main.async {
                    self.currentUser = user
                    print("Successfully fetched user: \(user.name ?? "Unknown")")
                }
            } catch {
                print("Error decoding user: \(error.localizedDescription)")
            }
        }
    }

    // Add this function to update current user
    func updateCurrentUser(_ user: User?) {
        DispatchQueue.main.async {
            self.currentUser = user
        }
    }

    func resetPassword(email: String, completion: @escaping (Bool, String?) -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                completion(false, error.localizedDescription)
            } else {
                completion(true, nil)
            }
        }
    }
}


//
//#Preview {
//    AuthViewModel()
//}

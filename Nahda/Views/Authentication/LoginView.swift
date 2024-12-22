//
//  LoginView.swift
//  Nahda
//
//  Created by mofo on 01.12.2024.
//
// LoginView.swift
import SwiftUI

// Add this extension for email validation
extension String {
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }
}

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var showResetPassword = false
    @State private var resetEmail = ""
    @State private var showResetAlert = false
    @State private var resetAlertMessage = ""
    @State private var isResetSuccess = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Nahda")
                    .font(.largeTitle)
                    .bold()

                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)

                SecureField("Password", text: $password)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }

                Button(action: login) {
                    Text("Sign In")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                }

                Button(action: { showResetPassword = true }) {
                    Text("Forgot Password?")
                        .foregroundColor(.blue)
                }
                .sheet(isPresented: $showResetPassword) {
                    ResetPasswordView(
                        resetEmail: $resetEmail,
                        showResetAlert: $showResetAlert,
                        resetAlertMessage: $resetAlertMessage,
                        isResetSuccess: $isResetSuccess,
                        onReset: resetPassword
                    )
                }

                NavigationLink("Don't have an account? Sign Up", destination: RegisterView())
                    .padding(.top)
            }
            .padding()
            .alert(isResetSuccess ? "Success" : "Error", isPresented: $showResetAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(resetAlertMessage)
            }
        }
    }

    func login() {
        authViewModel.login(email: email, password: password) { success, error in
            if !success {
                self.errorMessage = error
            }
        }
    }
    
    func resetPassword() {
        guard !resetEmail.isEmpty else {
            resetAlertMessage = "Please enter your email address"
            showResetAlert = true
            return
        }
        
        authViewModel.resetPassword(email: resetEmail) { success, message in
            resetAlertMessage = success ? 
                "Password reset email sent. Please check your inbox." : 
                message ?? "Failed to send reset email"
            isResetSuccess = success
            showResetAlert = true
            if success {
                resetEmail = ""
                showResetPassword = false
            }
        }
    }
}

// Update ResetPasswordView with enhanced validation and UI
struct ResetPasswordView: View {
    @Binding var resetEmail: String
    @Binding var showResetAlert: Bool
    @Binding var resetAlertMessage: String
    @Binding var isResetSuccess: Bool
    let onReset: () -> Void
    @Environment(\.presentationMode) var presentationMode
    @State private var isLoading = false
    @State private var emailError: String?
    @State private var isAppearing = false  // For initial animation
    @State private var isShaking = false    // For error animation
    @Namespace private var animation        // For matched geometry effect
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // App Icon with animation
                    Image(systemName: "lock.rotation")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                        .padding(.top, 40)
                        .rotationEffect(.degrees(isAppearing ? 0 : 180))
                        .scaleEffect(isAppearing ? 1 : 0.5)
                        .animation(.spring(response: 0.6, dampingFraction: 0.6), value: isAppearing)
                    
                    // Title and Description with fade
                    VStack(spacing: 12) {
                        Text("Reset Password")
                            .font(.title2)
                            .bold()
                            .opacity(isAppearing ? 1 : 0)
                            .offset(y: isAppearing ? 0 : 20)
                        
                        Text("Enter your email address and we'll send you instructions to reset your password.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .opacity(isAppearing ? 1 : 0)
                            .offset(y: isAppearing ? 0 : 20)
                    }
                    .animation(.easeOut.delay(0.2), value: isAppearing)
                    
                    // Email Input with shake animation
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Email", text: $resetEmail)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                            .onChange(of: resetEmail) { _ in
                                validateEmail()
                            }
                            .offset(x: isShaking ? -5 : 0)
                            .animation(
                                isShaking ? 
                                    .interpolatingSpring(mass: 1, stiffness: 100, damping: 5)
                                    .repeatCount(3, autoreverses: true) : 
                                    .default,
                                value: isShaking
                            )
                        
                        if let error = emailError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .opacity(isAppearing ? 1 : 0)
                    .offset(y: isAppearing ? 0 : 20)
                    .animation(.easeOut.delay(0.3), value: isAppearing)
                    
                    // Reset Button with loading animation
                    Button(action: {
                        withAnimation(.spring()) {
                            if validateEmail() {
                                isLoading = true
                                onReset()
                            } else {
                                isShaking = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    isShaking = false
                                }
                            }
                        }
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .padding(.trailing, 8)
                                    .transition(.scale.combined(with: .opacity))
                            }
                            Text("Send Reset Link")
                                .scaleEffect(isLoading ? 0.95 : 1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            resetEmail.isValidEmail ? 
                                Color.blue.opacity(isLoading ? 0.8 : 1) : 
                                Color.gray
                        )
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .scaleEffect(isLoading ? 0.98 : 1)
                    }
                    .disabled(!resetEmail.isValidEmail || isLoading)
                    .padding(.horizontal)
                    .opacity(isAppearing ? 1 : 0)
                    .offset(y: isAppearing ? 0 : 20)
                    .animation(.easeOut.delay(0.4), value: isAppearing)
                    
                    // Info rows with staggered animation
                    VStack(spacing: 16) {
                        ForEach(Array(["envelope", "clock", "lock.shield"].enumerated()), id: \.0) { index, icon in
                            InfoRow(
                                icon: icon,
                                text: [
                                    "Check your spam folder if you don't see the email",
                                    "The reset link expires in 1 hour",
                                    "Make sure to choose a strong password"
                                ][index]
                            )
                            .opacity(isAppearing ? 1 : 0)
                            .offset(y: isAppearing ? 0 : 20)
                            .animation(.easeOut.delay(0.5 + Double(index) * 0.1), value: isAppearing)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding()
                }
            }
            .navigationBarItems(
                leading: Button("Cancel") {
                    withAnimation {
                        isAppearing = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
            )
            .onAppear {
                withAnimation {
                    isAppearing = true
                }
            }
        }
    }
    
    private func validateEmail() -> Bool {
        if resetEmail.isEmpty {
            emailError = "Email is required"
            return false
        }
        if !resetEmail.isValidEmail {
            emailError = "Please enter a valid email address"
            return false
        }
        emailError = nil
        return true
    }
}

// Enhanced InfoRow with hover effect
struct InfoRow: View {
    let icon: String
    let text: String
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
                .rotationEffect(.degrees(isHovered ? 10 : 0))
            
            Text(text)
                .font(.caption)
                .foregroundColor(.gray)
            
            Spacer()
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isHovered = hovering
            }
        }
    }
}

#Preview {
    LoginView()
}

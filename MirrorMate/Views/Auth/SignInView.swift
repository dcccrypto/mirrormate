import SwiftUI

struct SignInView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authService = AuthService.shared
    
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var showForgotPassword = false
    @State private var resetEmail = ""
    @State private var showResetSuccess = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.xl) {
                        // Header
                        VStack(spacing: AppTheme.Spacing.sm) {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(AppTheme.Colors.primaryGradient)
                            
                            Text("Welcome Back")
                                .font(AppTheme.Fonts.title())
                                .foregroundColor(AppTheme.Colors.contrast)
                            
                            Text("Sign in to continue")
                                .font(AppTheme.Fonts.body())
                                .foregroundColor(AppTheme.Colors.secondaryText)
                        }
                        .padding(.top, AppTheme.Spacing.xxl)
                        
                        // Form
                        VStack(spacing: AppTheme.Spacing.lg) {
                            // Email Field
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                                Text("Email")
                                    .font(AppTheme.Fonts.subheadline())
                                    .foregroundColor(AppTheme.Colors.secondaryText)
                                
                                TextField("your@email.com", text: $email)
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .font(AppTheme.Fonts.body())
                                    .padding(AppTheme.Spacing.md)
                                    .background(AppTheme.Colors.secondaryBackground)
                                    .cornerRadius(AppTheme.CornerRadius.md)
                            }
                            
                            // Password Field
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                                Text("Password")
                                    .font(AppTheme.Fonts.subheadline())
                                    .foregroundColor(AppTheme.Colors.secondaryText)
                                
                                SecureField("••••••••", text: $password)
                                    .textContentType(.password)
                                    .font(AppTheme.Fonts.body())
                                    .padding(AppTheme.Spacing.md)
                                    .background(AppTheme.Colors.secondaryBackground)
                                    .cornerRadius(AppTheme.CornerRadius.md)
                            }
                            
                            // Forgot Password
                            HStack {
                                Spacer()
                                Button(action: {
                                    showForgotPassword = true
                                    HapticFeedback.light.trigger()
                                }) {
                                    Text("Forgot Password?")
                                        .font(AppTheme.Fonts.subheadline())
                                        .foregroundColor(AppTheme.Colors.primary)
                                }
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.xl)
                        
                        // Error Message
                        if let error = errorMessage {
                            HStack(spacing: AppTheme.Spacing.sm) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(AppTheme.Colors.error)
                                Text(error)
                                    .font(AppTheme.Fonts.subheadline())
                                    .foregroundColor(AppTheme.Colors.error)
                            }
                            .padding(AppTheme.Spacing.md)
                            .frame(maxWidth: .infinity)
                            .background(AppTheme.Colors.error.opacity(0.1))
                            .cornerRadius(AppTheme.CornerRadius.md)
                            .padding(.horizontal, AppTheme.Spacing.xl)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        
                        // Sign In Button
                        Button(action: { Task { await handleSignIn() } }) {
                            HStack(spacing: AppTheme.Spacing.sm) {
                                if authService.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Sign In")
                                        .font(AppTheme.Fonts.headline())
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppTheme.Spacing.md)
                            .background(AppTheme.Colors.primaryGradient)
                            .cornerRadius(AppTheme.CornerRadius.md)
                            .opacity(isFormValid ? 1 : 0.6)
                        }
                        .disabled(!isFormValid || authService.isLoading)
                        .bounceButton()
                        .padding(.horizontal, AppTheme.Spacing.xl)
                        
                        Spacer()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                        HapticFeedback.light.trigger()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(AppTheme.Colors.contrast)
                    }
                }
            }
            .alert("Reset Password", isPresented: $showForgotPassword) {
                TextField("Email", text: $resetEmail)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                
                Button("Cancel", role: .cancel) { }
                Button("Send Reset Link") {
                    Task { await handlePasswordReset() }
                }
            } message: {
                Text("Enter your email to receive a password reset link")
            }
            .alert("Check Your Email", isPresented: $showResetSuccess) {
                Button("OK") { }
            } message: {
                Text("We've sent a password reset link to \(resetEmail)")
            }
            .onChange(of: authService.isAuthenticated) { _, isAuth in
                if isAuth {
                    dismiss()
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && email.contains("@") && password.count >= 6
    }
    
    private func handleSignIn() async {
        errorMessage = nil
        
        do {
            try await authService.signIn(email: email, password: password)
            // Dismiss handled by onChange
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func handlePasswordReset() async {
        guard !resetEmail.isEmpty, resetEmail.contains("@") else {
            errorMessage = "Please enter a valid email"
            return
        }
        
        do {
            try await authService.resetPassword(email: resetEmail)
            showResetSuccess = true
            showForgotPassword = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}


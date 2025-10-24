import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authService = AuthService.shared
    
    @State private var displayName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?
    @State private var agreeToTerms = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.xl) {
                        // Header
                        VStack(spacing: AppTheme.Spacing.sm) {
                            Image(systemName: "person.crop.circle.fill.badge.plus")
                                .font(.system(size: 60))
                                .foregroundStyle(AppTheme.Colors.primaryGradient)
                            
                            Text("Create Account")
                                .font(AppTheme.Fonts.title())
                                .foregroundColor(AppTheme.Colors.contrast)
                            
                            Text("Join MirrorMate today")
                                .font(AppTheme.Fonts.body())
                                .foregroundColor(AppTheme.Colors.secondaryText)
                        }
                        .padding(.top, AppTheme.Spacing.xxl)
                        
                        // Form
                        VStack(spacing: AppTheme.Spacing.lg) {
                            // Display Name Field
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                                Text("Name")
                                    .font(AppTheme.Fonts.subheadline())
                                    .foregroundColor(AppTheme.Colors.secondaryText)
                                
                                TextField("Your name", text: $displayName)
                                    .textContentType(.name)
                                    .font(AppTheme.Fonts.body())
                                    .padding(AppTheme.Spacing.md)
                                    .background(AppTheme.Colors.secondaryBackground)
                                    .cornerRadius(AppTheme.CornerRadius.md)
                            }
                            
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
                                
                                SecureField("At least 6 characters", text: $password)
                                    .textContentType(.newPassword)
                                    .font(AppTheme.Fonts.body())
                                    .padding(AppTheme.Spacing.md)
                                    .background(AppTheme.Colors.secondaryBackground)
                                    .cornerRadius(AppTheme.CornerRadius.md)
                                
                                // Password strength indicator
                                if !password.isEmpty {
                                    HStack(spacing: AppTheme.Spacing.xs) {
                                        ForEach(0..<4) { index in
                                            Rectangle()
                                                .fill(index < passwordStrength ? strengthColor : AppTheme.Colors.tertiaryBackground)
                                                .frame(height: 4)
                                                .cornerRadius(2)
                                        }
                                    }
                                    
                                    Text(strengthText)
                                        .font(AppTheme.Fonts.caption())
                                        .foregroundColor(strengthColor)
                                }
                            }
                            
                            // Confirm Password Field
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                                Text("Confirm Password")
                                    .font(AppTheme.Fonts.subheadline())
                                    .foregroundColor(AppTheme.Colors.secondaryText)
                                
                                SecureField("Re-enter password", text: $confirmPassword)
                                    .textContentType(.newPassword)
                                    .font(AppTheme.Fonts.body())
                                    .padding(AppTheme.Spacing.md)
                                    .background(AppTheme.Colors.secondaryBackground)
                                    .cornerRadius(AppTheme.CornerRadius.md)
                                
                                if !confirmPassword.isEmpty && password != confirmPassword {
                                    HStack(spacing: 4) {
                                        Image(systemName: "xmark.circle.fill")
                                        Text("Passwords don't match")
                                    }
                                    .font(AppTheme.Fonts.caption())
                                    .foregroundColor(AppTheme.Colors.error)
                                }
                            }
                            
                            // Terms Agreement
                            HStack(spacing: AppTheme.Spacing.sm) {
                                Button(action: {
                                    agreeToTerms.toggle()
                                    HapticFeedback.selection.trigger()
                                }) {
                                    Image(systemName: agreeToTerms ? "checkmark.square.fill" : "square")
                                        .font(.system(size: 20))
                                        .foregroundColor(agreeToTerms ? AppTheme.Colors.primary : AppTheme.Colors.secondaryText)
                                }
                                
                                Text("I agree to the Terms of Service and Privacy Policy")
                                    .font(AppTheme.Fonts.caption())
                                    .foregroundColor(AppTheme.Colors.secondaryText)
                                
                                Spacer()
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
                        
                        // Sign Up Button
                        Button(action: { Task { await handleSignUp() } }) {
                            HStack(spacing: AppTheme.Spacing.sm) {
                                if authService.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Create Account")
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
            .onChange(of: authService.isAuthenticated) { _, isAuth in
                if isAuth {
                    dismiss()
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty &&
        email.contains("@") &&
        password.count >= 6 &&
        password == confirmPassword &&
        agreeToTerms
    }
    
    private var passwordStrength: Int {
        var strength = 0
        if password.count >= 6 { strength += 1 }
        if password.count >= 10 { strength += 1 }
        if password.rangeOfCharacter(from: .uppercaseLetters) != nil { strength += 1 }
        if password.rangeOfCharacter(from: .decimalDigits) != nil { strength += 1 }
        return strength
    }
    
    private var strengthColor: Color {
        switch passwordStrength {
        case 0...1: return AppTheme.Colors.error
        case 2: return AppTheme.Colors.warning
        case 3: return AppTheme.Colors.accent
        default: return AppTheme.Colors.success
        }
    }
    
    private var strengthText: String {
        switch passwordStrength {
        case 0...1: return "Weak"
        case 2: return "Fair"
        case 3: return "Good"
        default: return "Strong"
        }
    }
    
    private func handleSignUp() async {
        errorMessage = nil
        
        do {
            try await authService.signUp(
                email: email,
                password: password,
                displayName: displayName.isEmpty ? nil : displayName
            )
            // Dismiss handled by onChange
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}


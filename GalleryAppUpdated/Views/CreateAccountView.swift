import SwiftUI
import SwiftData
import LocalAuthentication

struct CreateAccountView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]

    @State private var username = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    @State private var errorMessage: String?

    @State private var biometricType: LABiometryType = .none
    private let biometricUserKey = "biometric_enabled_username"

    var body: some View {
        VStack(spacing: 24) {

            //Spacer()

            Text("Create Account")
                .font(.largeTitle.bold())
                .padding(.top, 75)

            VStack(spacing: 16) {

                TextField("Username", text: $username)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .modifier(InputFieldStyle())

                HStack {
                    Group {
                        if isPasswordVisible {
                            TextField("Password", text: $password)
                        } else {
                            SecureField("Password", text: $password)
                        }
                    }

                    Button {
                        isPasswordVisible.toggle()
                    } label: {
                        Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                            .foregroundColor(.secondary)
                    }
                }
                .modifier(InputFieldStyle())
            }
            .padding(.horizontal, 24)

            Button(action: createAccount) {
                Text("Create Account")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 24)

            // Biometric signup
            Button(action: authenticateAndCreateAccount) {
                VStack(spacing: 8) {
                    Image(systemName: biometricIconName)
                        .font(.system(size: 42))
                    Text(biometricText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.footnote)
            }

            Button("Already have an account? Sign in") {
                dismiss()
            }
            .font(.footnote)
            .foregroundColor(.blue)

            Spacer()
        }
        .onAppear(perform: detectBiometrics)
        .ignoresSafeArea(.container, edges: .top)
    }

    // Account Creation
    private func createAccount() {
        let name = username.lowercased()

        guard name.count >= 3 else {
            errorMessage = "Username must be at least 3 characters"
            return
        }

        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            return
        }

        guard !users.contains(where: { $0.username == name }) else {
            errorMessage = "Account already exists"
            return
        }

        let user = User(username: name, email: "\(name)@gallery.com")
        modelContext.insert(user)
    

        if KeychainManager.shared.savePassword(password, for: name) {
            UserDefaults.standard.set(name, forKey: biometricUserKey)
            try? modelContext.save()
            dismiss()
        } else {
            errorMessage = "Failed to save password"
        }
    }

    // Biometrics Signup
    private func authenticateAndCreateAccount() {
        let context = LAContext()
        context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: "Create account using biometrics"
        ) { success, _ in
            DispatchQueue.main.async {
                if success {
                    createAccount()
                } else {
                    errorMessage = "Biometric authentication failed"
                }
            }
        }
    }

    private func detectBiometrics() {
        let context = LAContext()
        biometricType = context.biometryType
    }

    private var biometricIconName: String {
        biometricType == .faceID ? "faceid" : "touchid"
    }

    private var biometricText: String {
        biometricType == .faceID ? "Create with Face ID" : "Create with Touch ID"
    }
}

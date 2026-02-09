import SwiftUI
import SwiftData
import LocalAuthentication

struct LoginView: View {

    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]

    @State private var username = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    @State private var errorMessage: String?

    @State private var isLoggedIn = false
    @State private var showCreateAccount = false
    @State private var loggedInUser: User?

    // Face ID
    @State private var biometricType: LABiometryType = .none
    @State private var biometricUsername: String?

    private let biometricUserKey = "biometric_enabled_username"

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {

               // Spacer()

                Text("Gallery App")
                    .font(.largeTitle.bold())
                    .padding(.top, 16)

                VStack(spacing: 16) {

                    // Username
                    TextField("Username", text: $username)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .modifier(InputFieldStyle())

                    // Password
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

                // Login button
                Button(action: handleLogin) {
                    Text("Login")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)

                // Face ID button (only when supported)
                #if targetEnvironment(simulator)
                let showFaceIDButton = true
                #else
                let showFaceIDButton = biometricType == .faceID
                #endif

                if showFaceIDButton {
                    Button(action: authenticateWithBiometrics) {
                        VStack(spacing: 8) {
                            Image(systemName: "faceid")
                                .font(.system(size: 42))
                            Text("Login with Face ID")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                }

                Button {
                    showCreateAccount = true
                } label: {
                    Text("Create a new account")
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(.blue)
                }

                Spacer()
            }
            .onAppear(perform: checkBiometrics)
            .onChange(of: isLoggedIn) { oldValue, newValue in
                // Clear credentials when returning to login screen
                if oldValue == true && newValue == false {
                    username = ""
                    password = ""
                    errorMessage = nil
                }
            }
            .navigationDestination(isPresented: $isLoggedIn) {
                if let user = loggedInUser {
                    MainTabView(user: user)
                }
            }
            .navigationDestination(isPresented: $showCreateAccount) {
                CreateAccountView()
            }
        }
    }

    // Login
    private func handleLogin() {
        errorMessage = nil
        let name = username.lowercased()

        guard let user = users.first(where: { $0.username == name }) else {
            errorMessage = "Account does not exist"
            return
        }

        guard let stored = KeychainManager.shared.getPassword(for: name),
              stored == password else {
            errorMessage = "Incorrect password"
            return
        }

        UserDefaults.standard.set(name, forKey: biometricUserKey)
        loggedInUser = user
        isLoggedIn = true
    }

    // Face ID
    private func checkBiometrics() {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            biometricType = context.biometryType
            biometricUsername = UserDefaults.standard.string(forKey: biometricUserKey)
        } else {
            biometricType = .none
        }
    }

    private func authenticateWithBiometrics() {
        guard let name = biometricUsername,
              let user = users.first(where: { $0.username == name }) else {
            errorMessage = "Face ID login not set up"
            return
        }

        let context = LAContext()
        context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: "Login using Face ID"
        ) { success, _ in
            DispatchQueue.main.async {
                if success {
                    loggedInUser = user
                    isLoggedIn = true
                } else {
                    errorMessage = "Face ID authentication failed"
                }
            }
        }
    }
}

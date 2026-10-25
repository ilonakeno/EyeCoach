import SwiftUI
import FirebaseAuth

struct SecuritySettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var userManager: UserManager
    
    // Стани для зміни пароля
    @State private var newPassword = ""
    @State private var message = ""
    @State private var isError = false
    
    // Стани для подвійного підтвердження видалення
    @State private var showFirstDeleteAlert = false
    @State private var showSecondDeleteAlert = false
    @State private var showReauthAlert = false
    
    var body: some View {
        Form {
            // 🔥 СЕКЦІЯ 1: ЗМІНА ПАРОЛЯ 🔥
            Section(header: Text("Change Password"), footer: Text("Only applies if you registered with Email.")) {
                SecureField("New Password (min 6 chars)", text: $newPassword)
                    .textContentType(.newPassword)
                
                Button("Update Password") {
                    updatePassword()
                }
                .disabled(newPassword.count < 6)
            }
            
            if !message.isEmpty {
                Text(message).foregroundColor(isError ? .red : .green).font(.caption)
            }
            
            // 🔥 СЕКЦІЯ 2: ВИДАЛЕННЯ АКАУНТУ 🔥
            Section {
                Button(action: {
                    showFirstDeleteAlert = true
                }) {
                    Text("Delete Account")
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .navigationTitle("Security")
        .navigationBarTitleDisplayMode(.inline)
        
        // 🚨 КРОК 1: ПЕРШЕ ПІДТВЕРДЖЕННЯ 🚨
        .alert("Delete Account?", isPresented: $showFirstDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                // Запускаємо другий алерт з мікро-затримкою, щоб SwiftUI не зглючив
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showSecondDeleteAlert = true
                }
            }
        } message: {
            Text("Are you sure you want to delete your account?")
        }
        
        // 🚨 КРОК 2: ФІНАЛЬНИЙ ВОРНІНГ 🚨
        .alert("Warning", isPresented: $showSecondDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Yes, delete", role: .destructive) {
                userManager.deleteUserAccount { success, errorMessage in
                    if !success {
                        self.showReauthAlert = true
                    } else {
                        dismiss()
                    }
                }
            }
        } message: {
            Text("This action will permanently erase your profile and all progress. It cannot be undone.")
        }
        
        // 🚨 РЕЗЕРВНИЙ АЛЕРТ: Якщо Apple/Firebase заблокує видалення через старий вхід 🚨
        .alert("Session Expired", isPresented: $showReauthAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Log Out", role: .destructive) {
                try? Auth.auth().signOut()
                withAnimation { userManager.isUserLoggedIn = false }
                dismiss()
            }
        } message: {
            Text("Please log out and log in again to verify your identity before deleting.")
        }
    }
    
    // MARK: - ЛОГІКА ОНОВЛЕННЯ ПАРОЛЯ
    private func updatePassword() {
        Auth.auth().currentUser?.updatePassword(to: newPassword) { error in
            if let error = error {
                message = error.localizedDescription
                isError = true
            } else {
                message = "Password updated successfully!"
                isError = false
                newPassword = ""
            }
        }
    }
}

#Preview {
    let mock = UserManager()
    return SecuritySettingsView()
        .environmentObject(mock)
}

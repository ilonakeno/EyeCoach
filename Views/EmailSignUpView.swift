import SwiftUI
import FirebaseAuth

struct EmailSignUpView: View {
    // Використовуємо класичний presentationMode для закриття вікна
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var userManager: UserManager
    
    // Режими екрану
    @State private var isLoginMode = false // false = Реєстрація, true = Вхід
    
    // Поля вводу
    @State private var email = ""
    @State private var password = ""
    
    // Стани для помилок та алертів
    @State private var errorMessage = ""
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    let brandColor = Color(hex: "6155F5")
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Заголовок
                Text(isLoginMode ? "Welcome Back!" : "Create Account")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 40)
                
                Text(isLoginMode ? "Log in to continue your training" : "Sign up to start your journey")
                    .foregroundColor(.gray)
                    .padding(.bottom, 20)
                
                // Поля вводу
                VStack(spacing: 15) {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    
                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                
                // 🔴 Кнопка Forgot Password (показуємо тільки при логіні)
                if isLoginMode {
                    HStack {
                        Spacer()
                        Button(action: resetPassword) {
                            Text("Forgot Password?")
                                .font(.footnote)
                                .fontWeight(.semibold)
                                .foregroundColor(brandColor)
                        }
                    }
                    .padding(.horizontal, 24)
                }
                
                // Текст помилки (якщо є)
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                
                // Головна кнопка дії
                Button(action: handleAction) {
                    Text(isLoginMode ? "Log In" : "Sign Up")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(brandColor)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .padding(.top, 10)
                
                Spacer()
                
                // Перемикач між Входом і Реєстрацією
                Button(action: {
                    withAnimation {
                        isLoginMode.toggle()
                        errorMessage = "" // Очищаємо помилки при перемиканні
                    }
                }) {
                    HStack(spacing: 4) {
                        Text(isLoginMode ? "Don't have an account?" : "Already have an account?")
                            .foregroundColor(.gray)
                        Text(isLoginMode ? "Sign Up" : "Log In")
                            .fontWeight(.bold)
                            .foregroundColor(brandColor)
                    }
                    .font(.footnote)
                }
                .padding(.bottom, 30)
            }
            // Алерт для скидання пароля
            .alert(isPresented: $showAlert) {
                Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .navigationBarItems(leading: Button(action: { presentationMode.wrappedValue.dismiss() }) {
                Image(systemName: "xmark")
                    .foregroundColor(.primary)
                    .font(.title3)
            })
        }
    }
    
    // MARK: - Логіка кнопок
    
    private func handleAction() {
        errorMessage = ""
        
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }
        
        if isLoginMode {
            loginUser()
        } else {
            registerUser()
        }
    }
    
    private func registerUser() {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
                return
            }
            
            // Якщо успішно зареєструвалися
            userManager.userEmail = self.email
            userManager.isUserLoggedIn = true
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    private func loginUser() {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
                return
            }
            
            // Якщо успішно увійшли
            userManager.userEmail = self.email
            userManager.isUserLoggedIn = true
            
            // Запускаємо перевірку і завантаження даних користувача
            
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    // 🔥 Логіка скидання пароля
    private func resetPassword() {
        errorMessage = ""
        guard !email.isEmpty else {
            errorMessage = "Please enter your email to reset password."
            return
        }
        
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                self.errorMessage = error.localizedDescription
            } else {
                self.alertTitle = "Check your inbox"
                self.alertMessage = "We've sent you an email with instructions to reset your password."
                self.showAlert = true
            }
        }
    }
}

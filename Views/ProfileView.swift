import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var userManager: UserManager
    
    @AppStorage("textSizeMultiplier") var textSizeMultiplier: Double = 1.0
    @AppStorage("voiceGuidance") var voiceGuidance: Bool = true
    @AppStorage("notificationsEnabled") var notificationsEnabled: Bool = true
    @AppStorage("isDarkMode") var isDarkMode: Bool = false
    @AppStorage("selectedLanguage") var selectedLanguage: String = "English"
    
    @State private var showLogoutAlert = false
    @State private var showSetupSheet = false
    @State private var tempName = ""
    @State private var tempEmail = ""
    @State private var showImagePicker = false
    @State private var pickedImageData: Data? = nil
    @State private var showEmailSignUp = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        HStack {
                            Button(action: { dismiss() }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 40, height: 40)
                                    .background(Color.gray.opacity(0.4))
                                    .clipShape(Circle())
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                        if userManager.isUserLoggedIn {
                            // БЛОК З ФОТО ТА ІМ'ЯМ
                            VStack(spacing: 12) {
                                Button(action: { showImagePicker = true }) {
                                    ZStack(alignment: .bottomTrailing) {
                                        if let data = userManager.profileImageData, let uiImage = UIImage(data: data) {
                                            Image(uiImage: uiImage).resizable().scaledToFill().frame(width: 90, height: 90).clipShape(Circle())
                                        } else {
                                            Circle().fill(Color(hex: "EFA4A4")).frame(width: 90, height: 90)
                                                .overlay(Text(userManager.userName.isEmpty ? "U" : String(userManager.userName.prefix(1)).uppercased()).font(.system(size: CGFloat(40 * textSizeMultiplier), weight: .medium)).foregroundColor(.white))
                                        }
                                        Circle().fill(Color(hex: "6155F5")).frame(width: 28, height: 28).overlay(Image(systemName: "camera.fill").font(.system(size: 12)).foregroundColor(.white)).offset(x: 5, y: 5)
                                    }
                                }
                                Text(userManager.userName.isEmpty ? "Your Name" : userManager.userName).font(.system(size: CGFloat(28 * textSizeMultiplier), weight: .bold))
                            }
                            
                            SettingsSection(title: "Progress") {
                                HStack { Text("Current Streak").font(.system(size: CGFloat(17 * textSizeMultiplier))).foregroundColor(.primary); Spacer(); Text("\(userManager.streakCount) 🔥").font(.system(size: CGFloat(17 * textSizeMultiplier), weight: .bold)).foregroundColor(Color(hex: "6155F5")) }
                                Divider()
                                HStack { Text("Exercises Today").font(.system(size: CGFloat(17 * textSizeMultiplier))).foregroundColor(.primary); Spacer(); Text("\(userManager.exercisesToday) / 3 ✅").font(.system(size: CGFloat(17 * textSizeMultiplier), weight: .bold)).foregroundColor(Color(hex: "6155F5")) }
                            }
                            
                            SettingsSection(title: "Account") {
                                Button(action: {
                                    self.tempName = userManager.userName; self.tempEmail = userManager.userEmail; self.showSetupSheet = true
                                }) { SettingsRow(title: "Edit profile / Medical conditions") }.buttonStyle(PlainButtonStyle())
                                
                                Divider()
                                
                                // ТУТ ВХІД В ОКРЕМИЙ РОЗДІЛ
                                NavigationLink(destination: SecuritySettingsView().environmentObject(userManager)) {
                                    SettingsRow(title: "Login & Security")
                                }.buttonStyle(PlainButtonStyle())
                            }
                            
                        } else {
                            // БЛОК ДЛЯ НЕАВТОРИЗОВАНИХ
                            VStack(spacing: 16) {
                                Text("Log in to save your progress & medical data").font(.system(size: CGFloat(22 * textSizeMultiplier), weight: .bold)).foregroundColor(.primary).multilineTextAlignment(.center).padding(.horizontal).padding(.bottom, 20)
                                
                                Button(action: {
                                    AuthManager.shared.startSignInWithAppleFlow { name, email, isNewUser, userData in
                                        if isNewUser { self.tempName = name; self.tempEmail = email; self.showSetupSheet = true } else { userManager.fetchUserDataFromCloud() }
                                    }
                                }) { HStack { Image(systemName: "applelogo").font(.system(size: 20)); Text("Continue with Apple").font(.system(size: CGFloat(17 * textSizeMultiplier), weight: .bold)) }.foregroundColor(.white).frame(maxWidth: .infinity, minHeight: 54).background(Color.black).cornerRadius(14) }
                                
                                Button(action: {
                                    AuthManager.shared.startSignInWithGoogleFlow { name, email, isNewUser, userData in
                                        if isNewUser { self.tempName = name; self.tempEmail = email; self.showSetupSheet = true } else { userManager.fetchUserDataFromCloud() }
                                    }
                                }) { HStack { Image(systemName: "g.circle.fill").font(.system(size: 20)); Text("Continue with Google").font(.system(size: CGFloat(17 * textSizeMultiplier), weight: .bold)) }.foregroundColor(.primary).frame(maxWidth: .infinity, minHeight: 54).background(Color(.secondarySystemGroupedBackground)).cornerRadius(14) }
                                
                                Button(action: { self.showEmailSignUp = true }) { HStack { Image(systemName: "envelope.fill").font(.system(size: 20)); Text("Continue with Email").font(.system(size: CGFloat(17 * textSizeMultiplier), weight: .bold)) }.foregroundColor(.white).frame(maxWidth: .infinity, minHeight: 54).background(Color(hex: "6155F5")).cornerRadius(14) }
                            }.padding(.horizontal, 20)
                        }

                        // ІНШІ НАЛАШТУВАННЯ
                        SettingsSection(title: "Accessibility") {
                            Toggle(isOn: $voiceGuidance) { Text("Voice guidance").font(.system(size: CGFloat(17 * textSizeMultiplier))) }.tint(Color(hex: "6155F5"))
                            Divider()
                            VStack(alignment: .leading, spacing: 10) { Text("Size").font(.system(size: CGFloat(17 * textSizeMultiplier))); HStack { Text("A").font(.system(size: 14)); Slider(value: $textSizeMultiplier, in: 1.0...1.5, step: 0.1).accentColor(Color(hex: "6155F5")); Text("A").font(.system(size: 24)).bold() } }
                        }

                        SettingsSection(title: "Settings") {
                            Toggle(isOn: $notificationsEnabled) { Text("Notification").font(.system(size: CGFloat(17 * textSizeMultiplier))) }.tint(.green).onChange(of: notificationsEnabled) { isEnabled in if isEnabled { userManager.requestAndScheduleNotifications() } else { userManager.cancelNotifications() } }
                            Divider()
                            Toggle(isOn: $isDarkMode) { Text("Dark mode").font(.system(size: CGFloat(17 * textSizeMultiplier))) }.tint(Color(hex: "6155F5"))
                            Divider()
                            HStack { Text("Language").font(.system(size: CGFloat(17 * textSizeMultiplier))); Spacer(); Text(selectedLanguage).font(.system(size: CGFloat(17 * textSizeMultiplier))).foregroundColor(Color(hex: "6155F5")); Image(systemName: "chevron.up.chevron.down").font(.system(size: 12)).foregroundColor(Color(hex: "6155F5")) }
                        }
                        
                        SettingsSection(title: "Support & About") {
                            Button(action: { if let url = URL(string: "mailto:support@eyecoach.app") { UIApplication.shared.open(url) } }) { SettingsRow(title: "Contact Support") }.buttonStyle(PlainButtonStyle())
                            Divider()
                            NavigationLink(destination: LegalDocumentView(title: "Privacy Policy", content: privacyPolicyText)) { SettingsRow(title: "Privacy Policy") }.buttonStyle(PlainButtonStyle())
                            Divider()
                            NavigationLink(destination: LegalDocumentView(title: "Terms of Use", content: termsOfUseText)) { SettingsRow(title: "Terms of Use") }.buttonStyle(PlainButtonStyle())
                        }

                        if userManager.isUserLoggedIn {
                            Button(action: { showLogoutAlert = true }) { Text("Log out").font(.system(size: CGFloat(17 * textSizeMultiplier), weight: .bold)).foregroundColor(.red).padding(.top, 10) }
                        }
                    }.padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
            .onChange(of: userManager.needsProfileSetup) { needs in
                if needs { self.tempName = ""; self.tempEmail = Auth.auth().currentUser?.email ?? ""; self.showSetupSheet = true; userManager.needsProfileSetup = false }
            }
            .sheet(isPresented: $showSetupSheet) { ProfileSetupView(isEditing: userManager.isUserLoggedIn, initialName: tempName, initialEmail: tempEmail) }
            .sheet(isPresented: $showEmailSignUp) { EmailSignUpView() }
            .sheet(isPresented: $showImagePicker) { ImagePicker(selectedImageData: $pickedImageData) }
            
            // ТУТ ФОТО ПЕРЕДАЄТЬСЯ В MANAGER
            .onChange(of: pickedImageData) { data in if let d = data { userManager.profileImageData = d; userManager.uploadProfileImage(d) } }
            
            .alert("Log Out?", isPresented: $showLogoutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Log Out", role: .destructive) {
                    try? Auth.auth().signOut()
                    userManager.userName = ""; userManager.userEmail = ""; userManager.isUserLoggedIn = false
                    userManager.streakCount = 0; userManager.exercisesToday = 0; userManager.profileImageData = nil
                    userManager.hasMyopia = false; userManager.hasAstigmatism = false; userManager.hasDryEye = false
                }
            } message: { Text("This will clear your local profile data and log you out. Are you sure?") }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}


// === ІНШІ ДОПОМІЖНІ КОМПОНЕНТИ ===
struct SettingsSection<Content: View>: View {
    var title: String
    let content: Content
    @AppStorage("textSizeMultiplier") var textSizeMultiplier: Double = 1.0
    init(title: String, @ViewBuilder content: () -> Content) { self.title = title; self.content = content() }
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.system(size: CGFloat(18 * textSizeMultiplier), weight: .bold)).foregroundColor(.primary).padding(.horizontal, 20)
            VStack(spacing: 12) { content }.padding(20).background(Color(.secondarySystemGroupedBackground)).cornerRadius(24).padding(.horizontal, 20)
        }
    }
}

struct SettingsRow: View {
    var title: String
    @AppStorage("textSizeMultiplier") var textSizeMultiplier: Double = 1.0
    var body: some View {
        HStack {
            Text(title).font(.system(size: CGFloat(17 * textSizeMultiplier))).foregroundColor(.primary)
            Spacer()
            Image(systemName: "chevron.right").foregroundColor(.gray.opacity(0.6)).font(.caption)
        }.contentShape(Rectangle())
    }
}

struct LegalDocumentView: View {
    let title: String
    let content: String
    var body: some View {
        ScrollView { Text(content).font(.body).foregroundColor(.primary).padding(20) }
        .navigationTitle(title).navigationBarTitleDisplayMode(.inline).background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}

let privacyPolicyText = """
Privacy Policy for EyeCoach

Last updated: March 2026

1. Information We Collect
We only collect information necessary to provide and improve the EyeCoach experience. This includes your account details (Name, Email, Profile Picture) when you sign in using Apple or Google. We also save your medical conditions (Myopia, Astigmatism, Dry Eye) locally on your device to personalize your experience.

2. Face Data and TrueDepth API
EyeCoach uses the device's TrueDepth camera API exclusively to track eye and head movements in real-time to guide you through eye exercises. This face tracking data is processed locally on your device. We do not record, collect, store, or share any face data, facial features, or biometric information with our servers or any third parties. The temporary tracking data is instantly discarded the moment the exercise is complete.

3. How We Use Your Information
Your data is used exclusively to:
- Track your daily exercise streaks.
- Personalize notifications.
- Sync your progress across devices (if signed in).

4. Data Storage and Security
We use industry-standard security measures (Firebase Auth) to protect your data. Your local app data is stored securely on your iOS device.

5. Third-Party Services
We use Apple Sign-In and Google Sign-In for authentication. We do not sell, rent, or share your personal data with ad networks or third parties.

6. Contact Us
If you have questions about this Privacy Policy, please contact us at ilona.keno03@gmail.com.
"""
let termsOfUseText = """
Terms of Use for EyeCoach

Last updated: March 2026

1. Acceptance of Terms
By accessing and using the EyeCoach app, you accept and agree to be bound by the terms and provision of this agreement.

2. Medical Disclaimer (Important)
EyeCoach is a wellness app designed to help reduce eye strain through basic exercises. EyeCoach is NOT a medical device, nor does it provide medical advice, diagnosis, or treatment. If you experience severe eye pain, sudden vision changes, or have pre-existing serious eye conditions, consult a certified ophthalmologist or medical professional immediately before using this app.

3. User Accounts
You are responsible for maintaining the confidentiality of your account credentials. You agree to accept responsibility for all activities that occur under your account.

4. App Usage
You agree to use EyeCoach only for its intended purposes. You may not reverse-engineer, decompile, or attempt to extract the source code of the app.

5. Changes to Terms
We reserve the right to modify these terms at any time. Your continued use of the app following any changes indicates your acceptance of the new terms.
"""

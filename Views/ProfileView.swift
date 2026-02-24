import SwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var userManager: UserManager
    
    @AppStorage("textSizeMultiplier") var textSizeMultiplier: Double = 1.0
    // 🔥 1. ВЕРНУЛИ APPSTORAGE ДЛЯ ЗВУКУ (за замовчуванням true - увімкнено)
    @AppStorage("voiceGuidance") var voiceGuidance: Bool = true
    @AppStorage("notificationsEnabled") var notificationsEnabled: Bool = true
    @AppStorage("isDarkMode") var isDarkMode: Bool = false
    @AppStorage("selectedLanguage") var selectedLanguage: String = "English"
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        
                        // 1. ШАПКА
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
                        
                        // 2. ДИНАМІЧНИЙ БЛОК: ПРОФІЛЬ АБО АВТОРИЗАЦІЯ
                        if userManager.isUserLoggedIn {
                            
                            VStack(spacing: 12) {
                                Circle()
                                    .fill(Color(hex: "EFA4A4"))
                                    .frame(width: 90, height: 90)
                                    .overlay(
                                        Text("Y")
                                            .font(.largeTitle)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                    )
                                
                                Text("Your Name")
                                    .font(.h2)
                                    .foregroundColor(.primary)
                            }
                            
                            SettingsSection(title: "Account") {
                                SettingsRow(title: "Edit profile / Medical conditions")
                                Divider()
                                SettingsRow(title: "Log in & Security")
                                Divider()
                                
                                NavigationLink(destination: PermissionsView()) {
                                    SettingsRow(title: "Permissions")
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            
                        } else {
                            
                            VStack(spacing: 16) {
                                Text("Log in to save your progress & medical data")
                                    .font(.h3)
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                    .padding(.bottom, 10)
                                
                                Button(action: { userManager.isUserLoggedIn = true }) {
                                    HStack {
                                        Image(systemName: "applelogo").font(.system(size: 20))
                                        Text("Continue with Apple").font(.bodyBold)
                                    }
                                    .foregroundColor(Color(.systemBackground))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.primary)
                                    .cornerRadius(14)
                                }
                                
                                Button(action: { userManager.isUserLoggedIn = true }) {
                                    HStack {
                                        Image(systemName: "g.circle.fill").font(.system(size: 20))
                                        Text("Continue with Google").font(.bodyBold)
                                    }
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color(.secondarySystemGroupedBackground))
                                    .cornerRadius(14)
                                    .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
                                }
                                
                                Button(action: { userManager.isUserLoggedIn = true }) {
                                    HStack {
                                        Image(systemName: "envelope.fill").font(.system(size: 20))
                                        Text("Continue with Email").font(.bodyBold)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color(hex: "6155F5"))
                                    .cornerRadius(14)
                                    .shadow(color: Color(hex: "6155F5").opacity(0.3), radius: 8, y: 4)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // 3. ACCESSIBILITY
                        SettingsSection(title: "Accessibility") {
                            // 🔥 2. ТУГЛ ПРАЦЮЄ НАПРЯМУ З APPSTORAGE 🔥
                            Toggle("Voice guidance", isOn: $voiceGuidance)
                                .tint(Color(hex: "6155F5"))
                            Divider()
                            
                            HStack {
                                Text("Size")
                                Spacer()
                                Text("A").font(.caption)
                                Slider(value: $textSizeMultiplier, in: 1.0...1.5, step: 0.1)
                                    .frame(width: 120)
                                    .accentColor(Color(hex: "6155F5"))
                                Text("A").font(.h3)
                            }
                        }
                        
                        // 4. SETTINGS
                        SettingsSection(title: "Settings") {
                            Toggle("Notification", isOn: $notificationsEnabled)
                                .tint(.green)
                            Divider()
                            Toggle("Dark mode", isOn: $isDarkMode)
                                .tint(Color(hex: "6155F5"))
                            Divider()
                            HStack {
                                Text("Language")
                                Spacer()
                                Text(selectedLanguage)
                                    .foregroundColor(Color(hex: "6155F5"))
                                Image(systemName: "chevron.up.chevron.down")
                                    .foregroundColor(Color(hex: "6155F5"))
                                    .font(.caption)
                            }
                        }
                        
                        if userManager.isUserLoggedIn {
                            Button(action: { userManager.isUserLoggedIn = false }) {
                                Text("Log out (For Testing)")
                                    .font(.bodyBold)
                                    .foregroundColor(.red)
                            }
                            .padding(.top, 10)
                        }
                        
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
        }
        .applySmartScale()
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}

// ДОПОМІЖНІ КОМПОНЕНТИ
struct SettingsSection<Content: View>: View {
    var title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.bodyBold)
                .foregroundColor(.primary)
                .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                content
                    .font(.bodyRegular)
                    .foregroundColor(.primary)
            }
            .padding(20)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(24)
            .padding(.horizontal, 20)
        }
    }
}

struct SettingsRow: View {
    var title: String
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray.opacity(0.6))
                .font(.caption)
        }
        .contentShape(Rectangle())
    }
}

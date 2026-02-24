import SwiftUI
import PhotosUI

struct AuthView: View {
    @EnvironmentObject var userManager: UserManager
    @State private var step: Int = 1
    
    // Для вибору фото при реєстрації
    @State private var selectedItem: PhotosPickerItem? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
                MeshBackground()
                
                VStack {
                    HStack {
                        Spacer()
                        Button("Skip") { userManager.showLoginSheet = false }
                            .foregroundColor(.gray).padding()
                    }
                    
                    if step == 1 { loginStep }
                    else if step == 2 { personalInfoStep }
                    else { conditionsStep }
                }
                .animation(.easeInOut, value: step)
            }
        }
    }
    
    var loginStep: some View {
        VStack(spacing: 20) {
            Text("Save your progress 📊").font(.h1)
            Text("Create an account to track your streak.").font(.bodyRegular).multilineTextAlignment(.center).padding(.horizontal)
            Spacer()
            SocialButton(icon: "apple.logo", text: "Sign in with Apple", color: .black) { step = 2 }
            SocialButton(icon: "g.circle.fill", text: "Sign in with Google", color: .blue) { step = 2 }
            SocialButton(icon: "envelope.fill", text: "Sign up with Email", color: .gray) { step = 2 }
            Spacer()
        }
        .padding()
    }
    
    var personalInfoStep: some View {
        VStack(spacing: 20) {
            Text("Tell us about you").font(.h2)
            
            // Фото пікер
            PhotosPicker(selection: $selectedItem, matching: .images) {
                if let data = userManager.currentUser.image, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage).resizable().scaledToFill()
                        .frame(width: 100, height: 100).clipShape(Circle())
                } else {
                    Circle().fill(Color.gray.opacity(0.2))
                        .frame(width: 100, height: 100)
                        .overlay(Image(systemName: "camera.fill").foregroundColor(.gray))
                }
            }
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        userManager.currentUser.image = data
                    }
                }
            }
            
            // НОВІ ПОЛЯ (виправляють помилку)
            CustomTextField(placeholder: "First Name", text: $userManager.currentUser.firstName)
            CustomTextField(placeholder: "Last Name", text: $userManager.currentUser.lastName)
            
            // Вибір дати замість введення віку
            DatePicker("Birthday", selection: $userManager.currentUser.birthday, displayedComponents: .date)
                .padding().background(Color.white).cornerRadius(12)
            
            Spacer()
            
            Button(action: { step = 3 }) {
                Text("Next").font(.bodyBold).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding().background(Color.primaryBlue).cornerRadius(15)
            }
        }
        .padding()
    }
    
    var conditionsStep: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Ocular Health").font(.h2)
                Text("Select conditions").font(.subhead).foregroundColor(.gray)
                
                ForEach(Array(userManager.currentUser.conditions.keys.sorted()), id: \.self) { key in
                    Toggle(key, isOn: Binding(
                        get: { userManager.currentUser.conditions[key] ?? false },
                        set: { userManager.currentUser.conditions[key] = $0 }
                    ))
                    .padding().liquidGlass()
                }
                
                Button(action: { userManager.login() }) {
                    Text("Finish Registration").font(.bodyBold).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding().background(Color.green).cornerRadius(15)
                }
                .padding(.bottom, 50)
            }
            .padding()
        }
    }
}

// Компоненти
struct SocialButton: View {
    let icon: String; let text: String; let color: Color; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack { Image(systemName: icon); Text(text) }
                .font(.bodyBold).foregroundColor(.white).frame(maxWidth: .infinity).padding().background(color).cornerRadius(15)
        }
    }
}

struct CustomTextField: View {
    let placeholder: String; @Binding var text: String
    var body: some View {
        TextField(placeholder, text: $text)
            .padding().background(Color.white).cornerRadius(12).shadow(color: .black.opacity(0.05), radius: 5)
    }
}

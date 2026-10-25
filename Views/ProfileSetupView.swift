import SwiftUI

struct ProfileSetupView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var userManager: UserManager
    
    // Режими екрану
    var isEditing: Bool // true = залогінений, false = завершує реєстрацію
    var initialName: String
    var initialEmail: String
    
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var birthDate: Date = Date()
    @State private var hasMyopia: Bool = false
    @State private var hasAstigmatism: Bool = false
    @State private var hasDryEye: Bool = false
    
    @State private var showImagePicker = false

    var body: some View {
        NavigationView {
            Form {
                // 🔥 СЕКЦІЯ ФОТО ПРОФІЛЮ 🔥
                Section {
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            showImagePicker = true
                        }) {
                            ZStack(alignment: .bottomTrailing) {
                                if let data = userManager.profileImageData, let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                } else {
                                    Circle()
                                        .fill(Color(hex: "EFA4A4"))
                                        .frame(width: 100, height: 100)
                                        .overlay(Image(systemName: "person.fill").font(.system(size: 40)).foregroundColor(.white))
                                }
                                Circle()
                                    .fill(Color(hex: "6155F5"))
                                    .frame(width: 32, height: 32)
                                    .overlay(Image(systemName: "camera.fill").font(.system(size: 14)).foregroundColor(.white))
                                    .offset(x: 5, y: 5)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
                
                // 🔥 ПЕРСОНАЛЬНІ ДАНІ 🔥
                Section(header: Text("Personal Info")) {
                    TextField("Full Name", text: $name)
                    TextField("Email Address", text: $email)
                        .disabled(true) // Пошту змінити не можна
                        .foregroundColor(.gray)
                    
                    DatePicker("Date of Birth", selection: $birthDate, displayedComponents: .date)
                }
                
                // 🔥 ДІАГНОЗИ 🔥
                Section(header: Text("My Diagnoses (Optional)"), footer: Text("This helps us tailor your experience.")) {
                    Toggle("Myopia (Nearsightedness)", isOn: $hasMyopia)
                    Toggle("Astigmatism", isOn: $hasAstigmatism)
                    Toggle("Dry Eye Syndrome", isOn: $hasDryEye)
                }
                
                // 🔥 КНОПКА ЗБЕРЕЖЕННЯ 🔥
                Section {
                    Button(action: saveProfile) {
                        Text(isEditing ? "Save Changes" : "Complete Setup")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .center)
                    }
                    .listRowBackground(Color(hex: "6155F5"))
                }
            }
            .navigationTitle(isEditing ? "Edit Profile" : "Account Setup")
            .navigationBarItems(trailing: Button(isEditing ? "Cancel" : "Skip for now") {
                if !isEditing { saveProfile() } else { dismiss() }
            })
            .onAppear(perform: loadInitialData)
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImageData: $userManager.profileImageData)
            }
        }
    }
    
    private func loadInitialData() {
        // АВТОЗАПОВНЕННЯ: Якщо Apple/Google дали дані - беремо їх. Інакше беремо з пам'яті.
        self.name = initialName.isEmpty ? userManager.userName : initialName
        self.email = initialEmail.isEmpty ? userManager.userEmail : initialEmail
        
        self.birthDate = userManager.birthDate
        self.hasMyopia = userManager.hasMyopia
        self.hasAstigmatism = userManager.hasAstigmatism
        self.hasDryEye = userManager.hasDryEye
    }
    
    private func saveProfile() {
        let finalName = name.trimmingCharacters(in: .whitespaces).isEmpty ? "User" : name
        
        // Зберігаємо локально
        userManager.userName = finalName
        userManager.userEmail = email
        userManager.birthDate = birthDate
        userManager.hasMyopia = hasMyopia
        userManager.hasAstigmatism = hasAstigmatism
        userManager.hasDryEye = hasDryEye
        
        // Ставимо статус логіну ДО збереження в базу
        if !isEditing {
            userManager.isUserLoggedIn = true
            userManager.requestAndScheduleNotifications()
        }
        
        // Відправляємо дані в хмару
        userManager.syncUserDataToCloud()
        
        // Відправляємо фото з мікро-затримкою
        if let imageData = userManager.profileImageData {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                userManager.uploadProfileImage(imageData)
            }
        }
        
        dismiss()
    }
}

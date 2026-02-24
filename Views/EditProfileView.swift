import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @EnvironmentObject var userManager: UserManager
    @Environment(\.dismiss) var dismiss
    
    // Стан редагування
    @State private var isEditing = false
    
    // Для вибору фото
    @State private var selectedItem: PhotosPickerItem? = nil
    
    var body: some View {
        ZStack {
            Color.bgBottom.opacity(0.3).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 25) {
                    
                    // --- ФОТО ПРОФІЛЮ ---
                    VStack {
                        ZStack(alignment: .bottomTrailing) {
                            // Відображення
                            if let data = userManager.currentUser.image, let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Color.red.opacity(0.5))
                                    .frame(width: 120, height: 120)
                                    .overlay(
                                        Text(userManager.currentUser.firstName.prefix(1))
                                            .font(.largeTitle)
                                            .foregroundColor(.white)
                                    )
                            }
                            
                            // Кнопка камери (активна тільки в режимі редагування)
                            if isEditing {
                                PhotosPicker(selection: $selectedItem, matching: .images) {
                                    Image(systemName: "camera.fill")
                                        .foregroundColor(.white)
                                        .padding(10)
                                        .background(Color.blue)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.white, lineWidth: 3))
                                }
                                .offset(x: 5, y: 5)
                            }
                        }
                        .shadow(radius: 5)
                    }
                    .padding(.top)
                    
                    // --- ПОЛЯ ВВОДУ ---
                    VStack(spacing: 0) {
                        if isEditing {
                            // РЕЖИМ РЕДАГУВАННЯ
                            EditRow(label: "First Name", text: $userManager.currentUser.firstName)
                            Divider()
                            EditRow(label: "Last Name", text: $userManager.currentUser.lastName)
                            Divider()
                            DatePickerRow(label: "Birthday", date: $userManager.currentUser.birthday)
                            Divider()
                            PickerRow(label: "Sex", selection: $userManager.currentUser.sex)
                        } else {
                            // РЕЖИМ ПЕРЕГЛЯДУ
                            InfoRow(label: "First Name", value: userManager.currentUser.firstName)
                            Divider()
                            InfoRow(label: "Last Name", value: userManager.currentUser.lastName)
                            Divider()
                            InfoRow(label: "Birthday", value: formatDate(userManager.currentUser.birthday))
                            Divider()
                            InfoRow(label: "Sex", value: userManager.currentUser.sex)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(20)
                    .padding(.horizontal)
                    
                    // --- ЗДОРОВ'Я ОЧЕЙ ---
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Ocular Health")
                            .font(.h3)
                            .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Do you have any diagnosed eye conditions?")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.bottom, 5)
                            
                            ForEach(Array(userManager.currentUser.conditions.keys.sorted()), id: \.self) { key in
                                Toggle(isOn: Binding(
                                    get: { userManager.currentUser.conditions[key] ?? false },
                                    set: { if isEditing { userManager.currentUser.conditions[key] = $0 } }
                                )) {
                                    Text(key)
                                        .font(.bodyBold)
                                        .foregroundColor(.black)
                                }
                                .toggleStyle(SwitchToggleStyle(tint: .green))
                                .padding(.vertical, 5)
                                .disabled(!isEditing)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(20)
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    if isEditing { userManager.saveUser() }
                    withAnimation { isEditing.toggle() }
                }) {
                    if isEditing {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.black)
                            .font(.title2)
                    } else {
                        Text("Edit")
                            .padding(.horizontal, 15)
                            .padding(.vertical, 8)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(20)
                            .foregroundColor(.black)
                            .font(.subheadline)
                    }
                }
            }
        }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    userManager.currentUser.image = data
                    userManager.saveUser()
                }
            }
        }
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        let dateString = formatter.string(from: date)
        let age = Calendar.current.dateComponents([.year], from: date, to: Date()).year ?? 0
        return "\(dateString) (\(age))"
    }
}

// --- 👇 ОСЬ ЦІ КОМПОНЕНТИ, ЯКИХ НЕ ВИСТАЧАЛО 👇 ---

struct InfoRow: View {
    let label: String; let value: String
    var body: some View {
        HStack {
            Text(label).font(.bodyRegular).foregroundColor(.gray) // Сірий для лейблу
            Spacer()
            Text(value.isEmpty ? "-" : value).font(.bodyRegular).foregroundColor(.blue) // Синій для значення
        }.padding(.vertical, 12)
    }
}

struct EditRow: View {
    let label: String; @Binding var text: String
    var body: some View {
        HStack {
            Text(label).font(.bodyRegular).foregroundColor(.gray)
            Spacer()
            TextField("Enter \(label)", text: $text).multilineTextAlignment(.trailing).foregroundColor(.black)
        }.padding(.vertical, 12)
    }
}

struct DatePickerRow: View {
    let label: String; @Binding var date: Date
    var body: some View {
        HStack {
            Text(label).font(.bodyRegular).foregroundColor(.gray)
            Spacer()
            DatePicker("", selection: $date, displayedComponents: .date).labelsHidden()
        }.padding(.vertical, 8)
    }
}

struct PickerRow: View {
    let label: String; @Binding var selection: String
    let options = ["Male", "Female", "Other"]
    var body: some View {
        HStack {
            Text(label).font(.bodyRegular).foregroundColor(.gray)
            Spacer()
            Picker("", selection: $selection) {
                ForEach(options, id: \.self) { Text($0).tag($0) }
            }.pickerStyle(.menu).accentColor(.blue)
        }.padding(.vertical, 8)
    }
}

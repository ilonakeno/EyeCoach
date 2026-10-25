import SwiftUI

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("isWearingGlasses") var isWearingGlasses: Bool = false
    
    @State private var firstName = "Name"
    @State private var lastName = "Name"
    @State private var birthday = "01.01.2001 (25)"
    @State private var sex = "Male"
    
    @State private var conditions = [
        ("Nearsightedness (Myopia)", true),
        ("Farsightedness (Hyperopia)", false),
        ("Astigmatism", false),
        ("Lazy Eye (Amblyopia)", false),
        ("Eye Strain (Asthenopia)", false),
        ("Other (Please specify)", false)
    ]

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // ШАПКА
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark").font(.headline).foregroundColor(.gray).frame(width: 40, height: 40).background(Color.white).clipShape(Circle())
                    }
                    Spacer()
                    Text("Account").font(.headline).bold()
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "checkmark").font(.headline).foregroundColor(.black).frame(width: 40, height: 40).background(Color.white).clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20).padding(.top, 10)
                
                ScrollView {
                    VStack(spacing: 24) {
                        Circle().fill(Color(hex: "EFA4A4")).frame(width: 80, height: 80)
                        
                        // ОСНОВНА ІНФА (СИНІЙ КОЛІР)
                        VStack(spacing: 0) {
                            editRow(label: "First Name", value: $firstName)
                            Divider().padding(.leading)
                            editRow(label: "Last Name", value: $lastName)
                            Divider().padding(.leading)
                            editRow(label: "Birthday", value: $birthday)
                            Divider().padding(.leading)
                            editRow(label: "Sex", value: $sex)
                        }
                        .background(Color.white).cornerRadius(20).padding(.horizontal)
                        
                        // ЗДОРОВ'Я
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Ocular Health").font(.title3).bold().padding(.horizontal)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Toggle("Are you wearing glasses right now?", isOn: $isWearingGlasses)
                                    .tint(.green)
                                
                                Divider().padding(.vertical, 5)
                                
                                Text("Do you have any diagnosed eye conditions?").font(.subheadline).bold()
                                Text("(Select all that apply to help us customize your exercises)").font(.caption).foregroundColor(.gray)
                                
                                ForEach(0..<conditions.count, id: \.self) { index in
                                    Toggle(conditions[index].0, isOn: .constant(conditions[index].1)).tint(.green)
                                }
                            }
                            .padding(20).background(Color.white).cornerRadius(20).padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    func editRow(label: String, value: Binding<String>) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField("", text: value)
                .multilineTextAlignment(.trailing)
                .foregroundColor(.blue) // ТЕ САМЕ СИНЄ ЗНАЧЕННЯ
        }
        .padding(16)
    }
}

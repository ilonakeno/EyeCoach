import SwiftUI
import Combine

struct UserProfile: Codable {
    var firstName: String = "Your"
    var lastName: String = "Name"
    var birthday: Date = Date()
    var sex: String = "Male"
    var image: Data? = nil
    
    // Налаштування (Frame 5)
    var voiceGuidance: Bool = false // 🔥 ЗМІНЕНО ТУТ: Тепер за замовчуванням вимкнено
    var notifications: Bool = true
    var darkMode: Bool = false
    var textSize: Double = 0.5
    
    var conditions: [String: Bool] = [
        "Nearsightedness (Myopia)": false,
        "Farsightedness (Hyperopia)": false,
        "Astigmatism": false,
        "Lazy Eye (Amblyopia)": false,
        "Eye Strain (Asthenopia)": false,
        "Other (Please specify)": false
    ]
}

class UserManager: ObservableObject {
    @AppStorage("isUserLoggedIn") var isUserLoggedIn: Bool = false
    @AppStorage("userProfileData") var userProfileData: Data = Data()
    
    @Published var currentUser: UserProfile = UserProfile()
    @Published var showLoginSheet: Bool = false
    
    init() { loadUser() }
    
    func loadUser() {
        if let decoded = try? JSONDecoder().decode(UserProfile.self, from: userProfileData) {
            currentUser = decoded
        }
    }
    
    func saveUser() {
        if let encoded = try? JSONEncoder().encode(currentUser) {
            userProfileData = encoded
        }
    }
    
    func login() {
        isUserLoggedIn = true
        showLoginSheet = false
        saveUser()
    }
    
    func logout() {
        isUserLoggedIn = false
        saveUser()
    }
    
    func triggerRegistration() {
        if !isUserLoggedIn { showLoginSheet = true }
    }
}

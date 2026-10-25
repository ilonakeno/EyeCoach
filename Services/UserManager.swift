import SwiftUI
import Combine
import UserNotifications
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

@MainActor
class UserManager: ObservableObject {
    @Published var showRegistrationPopup: Bool = false
    @Published var needsProfileSetup: Bool = false
    
    @Published var isUserLoggedIn: Bool = UserDefaults.standard.bool(forKey: "isUserLoggedIn") {
        didSet { UserDefaults.standard.set(isUserLoggedIn, forKey: "isUserLoggedIn") }
    }
    
    @Published var userName: String = UserDefaults.standard.string(forKey: "userName") ?? "" {
        didSet { UserDefaults.standard.set(userName, forKey: "userName") }
    }
    
    @Published var userEmail: String = UserDefaults.standard.string(forKey: "userEmail") ?? "" {
        didSet { UserDefaults.standard.set(userEmail, forKey: "userEmail") }
    }
    
    @Published var profileImageData: Data? = UserDefaults.standard.data(forKey: "profileImageData") {
        didSet {
            if let data = profileImageData {
                UserDefaults.standard.set(data, forKey: "profileImageData")
            } else {
                UserDefaults.standard.removeObject(forKey: "profileImageData")
            }
        }
    }
    
    @Published var birthDate: Date = UserDefaults.standard.object(forKey: "birthDate") as? Date ?? Date() {
        didSet { UserDefaults.standard.set(birthDate, forKey: "birthDate") }
    }
    
    @Published var hasMyopia: Bool = UserDefaults.standard.bool(forKey: "hasMyopia") {
        didSet { UserDefaults.standard.set(hasMyopia, forKey: "hasMyopia") }
    }
    
    @Published var hasAstigmatism: Bool = UserDefaults.standard.bool(forKey: "hasAstigmatism") {
        didSet { UserDefaults.standard.set(hasAstigmatism, forKey: "hasAstigmatism") }
    }
    
    @Published var hasDryEye: Bool = UserDefaults.standard.bool(forKey: "hasDryEye") {
        didSet { UserDefaults.standard.set(hasDryEye, forKey: "hasDryEye") }
    }
    
    @Published var streakCount: Int = UserDefaults.standard.integer(forKey: "streakCount") {
        didSet { UserDefaults.standard.set(streakCount, forKey: "streakCount") }
    }
    
    @Published var exercisesToday: Int = UserDefaults.standard.integer(forKey: "exercisesToday") {
        didSet { UserDefaults.standard.set(exercisesToday, forKey: "exercisesToday") }
    }
    
    @Published var lastExerciseDate: String = UserDefaults.standard.string(forKey: "lastExerciseDate") ?? "" {
        didSet { UserDefaults.standard.set(lastExerciseDate, forKey: "lastExerciseDate") }
    }

    init() {
        checkNewDay()
        
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            if user != nil {
                self.isUserLoggedIn = true
                self.fetchUserDataFromCloud()
            }
        }
    }
    
    func syncUserDataToCloud() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let data: [String: Any] = [
            "userName": userName, "userEmail": userEmail,
            "streakCount": streakCount, "exercisesToday": exercisesToday,
            "hasMyopia": hasMyopia, "hasAstigmatism": hasAstigmatism, "hasDryEye": hasDryEye
        ]
        db.collection("users").document(uid).setData(data, merge: true)
    }
    
    func fetchUserDataFromCloud() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        db.collection("users").document(uid).getDocument { snapshot, _ in
            if let data = snapshot?.data(), snapshot?.exists == true {
                DispatchQueue.main.async {
                    self.userName = data["userName"] as? String ?? ""
                    self.userEmail = data["userEmail"] as? String ?? ""
                    self.streakCount = data["streakCount"] as? Int ?? 0
                    self.exercisesToday = data["exercisesToday"] as? Int ?? 0
                    self.hasMyopia = data["hasMyopia"] as? Bool ?? false
                    self.hasAstigmatism = data["hasAstigmatism"] as? Bool ?? false
                    self.hasDryEye = data["hasDryEye"] as? Bool ?? false
                    
                    if self.userName.isEmpty { self.needsProfileSetup = true }
                    
                    if let imageUrl = data["profileImageUrl"] as? String {
                        self.fetchProfileImage(from: imageUrl)
                    }
                }
            } else {
                DispatchQueue.main.async { self.needsProfileSetup = true }
            }
        }
    }
    
    // 🔥 ВИПРАВЛЕНА ФУНКЦІЯ ЗАВАНТАЖЕННЯ ФОТО 🔥
    func uploadProfileImage(_ imageData: Data) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let ref = Storage.storage().reference().child("profile_images/\(uid).jpg")
        let metadata = StorageMetadata(); metadata.contentType = "image/jpeg"
        
        ref.putData(imageData, metadata: metadata) { _, error in
            if let error = error {
                print("❌ ПОМИЛКА STORAGE: \(error.localizedDescription)")
                return
            }
            ref.downloadURL { url, error in
                if let url = url {
                    // Використовуємо setData з merge: true замість updateData!
                    Firestore.firestore().collection("users").document(uid).setData(["profileImageUrl": url.absoluteString], merge: true)
                    print("✅ ФОТО УСПІШНО ЗБЕРЕЖЕНО В БАЗУ!")
                }
            }
        }
    }
    
    func fetchProfileImage(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data {
                DispatchQueue.main.async { self.profileImageData = data }
            } else if let error = error {
                print("❌ ПОМИЛКА ЗАВАНТАЖЕННЯ ФОТО З ХМАРИ: \(error.localizedDescription)")
            }
        }.resume()
    }

    // 🔥 ВИДАЛЕННЯ АКАУНТА 🔥
    func deleteUserAccount(completion: @escaping (Bool, String?) -> Void) {
        guard let user = Auth.auth().currentUser else { return }
        let uid = user.uid
        
        // Спочатку видаляємо з Firestore
        Firestore.firestore().collection("users").document(uid).delete { _ in
            // Потім видаляємо самого юзера з Auth
            user.delete { error in
                if let error = error {
                    completion(false, error.localizedDescription)
                    return
                }
                DispatchQueue.main.async {
                    self.clearLocalData()
                    completion(true, nil)
                }
            }
        }
    }
    
    private func clearLocalData() {
        self.userName = ""
        self.userEmail = ""
        self.isUserLoggedIn = false
        self.streakCount = 0
        self.exercisesToday = 0
        self.profileImageData = nil
        self.hasMyopia = false
        self.hasAstigmatism = false
        self.hasDryEye = false
    }

    func triggerRegistration() { showRegistrationPopup = true }

    func addExerciseCompleted() {
        checkNewDay()
        exercisesToday += 1
        if exercisesToday == 3 { streakCount += 1 }
        syncUserDataToCloud()
    }

    private func checkNewDay() {
        let today = DateFormatter(); today.dateFormat = "yyyy-MM-dd"
        let now = today.string(from: Date())
        if lastExerciseDate != now { exercisesToday = 0; lastExerciseDate = now }
    }

    func requestAndScheduleNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
    
    func cancelNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}

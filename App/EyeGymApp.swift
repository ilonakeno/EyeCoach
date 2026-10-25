import SwiftUI
import SwiftData
import FirebaseCore // 🔥 Підключаємо Firebase

// Створюємо делегат для ініціалізації Firebase при запуску
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure() // Вмикаємо базу
        return true
    }
}

@main
struct EyeGymApp: App {
    // Підключаємо делегат до SwiftUI
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @StateObject private var userManager = UserManager()
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false

    var body: some Scene {
        WindowGroup {
            if hasSeenOnboarding {
                HomeView()
                    .environmentObject(userManager)
                    .preferredColorScheme(isDarkMode ? .dark : .light)
            } else {
                InteractiveOnboardingView()
                    .environmentObject(userManager)
                    .preferredColorScheme(isDarkMode ? .dark : .light)
            }
        }
    }
}

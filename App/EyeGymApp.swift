import SwiftUI
import SwiftData

@main
struct EyeGymApp: App {
    @StateObject private var userManager = UserManager()
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    
    // 👇 Змінна стану для онбордингу
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    
    var body: some Scene {
        WindowGroup {
            if hasSeenOnboarding {
                HomeView()
                    .environmentObject(userManager)
                    .preferredColorScheme(isDarkMode ? .dark : .light)
            } else {
                // 👇 Викликаємо наш новий інтерактивний тур
                InteractiveOnboardingView()
                    .environmentObject(userManager)
                    .preferredColorScheme(isDarkMode ? .dark : .light)
            }
        }
    }
}

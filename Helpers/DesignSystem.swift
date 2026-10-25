import SwiftUI
import Combine
import SwiftData

// --- 1. РОЗУМНІ ШРИФТИ (РЕАГУЮТЬ НА СЛАЙДЕР) ---
extension Font {
    // Використовуємо системні стилі, які автоматично масштабуються
    static let h1 = Font.largeTitle.weight(.bold)           // ~34
    static let h2 = Font.title.weight(.bold)                // ~28
    static let h3 = Font.title2.weight(.semibold)           // ~22
    static let bodyBold = Font.body.weight(.semibold)       // ~17
    static let bodyRegular = Font.body.weight(.regular)     // ~17
    static let subhead = Font.subheadline.weight(.regular)  // ~15
    static let caption = Font.footnote.weight(.medium)      // ~13
    static let giantNumber = Font.system(size: 60, weight: .medium, design: .rounded) // Велику цифру залишаємо фіксованою
}

// --- 2. МАГІЯ МАСШТАБУВАННЯ (Зчитує слайдер) ---
struct TextScaler: ViewModifier {
    @AppStorage("textSizeMultiplier") var textSizeMultiplier: Double = 1.0
    
    func body(content: Content) -> some View {
        // Переводимо цифри зі слайдера в системні стандарти Apple для людей з вадами зору
        let size: DynamicTypeSize
        if textSizeMultiplier < 1.1 { size = .large } // Звичайний розмір
        else if textSizeMultiplier < 1.2 { size = .xLarge }
        else if textSizeMultiplier < 1.3 { size = .xxLarge }
        else if textSizeMultiplier < 1.4 { size = .xxxLarge }
        else if textSizeMultiplier < 1.5 { size = .accessibility1 }
        else { size = .accessibility2 } // Максимальний
        
        return content.dynamicTypeSize(size)
    }
}

extension View {
    func applySmartScale() -> some View {
        self.modifier(TextScaler())
    }
}

// --- 3. КОЛЬОРИ ---
extension Color {
    static let meshTopLeft = Color(hex: "a18cd1")
    static let meshTopRight = Color(hex: "fbc2eb")
    static let meshBottom = Color(hex: "8fd3f4")
    
    static let bgTop = Color(hex: "D8DFFC")
    static let bgBottom = Color(hex: "F2E9F9")
    static let primaryBlue = Color(hex: "5B67CA")
    static let cardWhite = Color.white.opacity(0.7)
}

// --- 4. ТИПИ СПИСКІВ ---
enum ListType {
    case myList
    case allList
    case eyeReliever
}

// --- 5. ДАНІ ТА ЛОГІКА ---
struct ExerciseItem: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var icon: String
    var isAdded: Bool
}

class AppData: ObservableObject {
    @Published var allExercises: [ExerciseItem] = [
        
        ExerciseItem(title: "Blinking", icon: "Blinking", isAdded: true),
        ExerciseItem(title: "Circle", icon: "Circle", isAdded: true),
        ExerciseItem(title: "Horizon", icon: "Horizon", isAdded: false),
        ExerciseItem(title: "Vertical", icon: "Vertical", isAdded: false),
        ExerciseItem(title: "Figure 8", icon: "Figure 8", isAdded: false),
        ExerciseItem(title: "Massage", icon: "Massage", isAdded: false),
        ExerciseItem(title: "Focus", icon: "Focus", isAdded: false),
        ExerciseItem(title: "Zig Zag", icon: "Zig Zag", isAdded: false),
        ExerciseItem(title: "Spiral", icon: "Spiral", isAdded: false),
        ExerciseItem(title: "Blink and Focus", icon: "Blink and Focus", isAdded: false),
        ExerciseItem(title: "Unfocus", icon: "Focus & Blink", isAdded: false),

       
    
        
    ]
    
    var myExercises: [ExerciseItem] { allExercises.filter { $0.isAdded } }
    var eyeRelieverExercises: [ExerciseItem] { allExercises.filter { $0.title == "Blinking"  || $0.title == "Blink and Focus" || $0.title == "Massage" || $0.title == "Circle" || $0.title == "Unfocus"} }
    
    func toggleAdd(for exercise: ExerciseItem) {
        if let index = allExercises.firstIndex(where: { $0.id == exercise.id }) {
            allExercises[index].isAdded.toggle()
        }
    }
}

// --- 6. HEX HELPER ---
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

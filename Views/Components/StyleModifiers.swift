import SwiftUI

// --- 1. РОЗУМНИЙ ФОН З ГРАДІЄНТАМИ (ЯСКРАВІШИЙ!) ---
struct MeshBackground: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // БАЗОВИЙ ФОН: Глибокий чорний вночі, світлий вдень
            (colorScheme == .dark ? Color.black : Color(hex: "F7F5FA"))
                .ignoresSafeArea()
            
            // КОЛЬОРОВІ ГРАДІЄНТИ
            GeometryReader { proxy in
                ZStack {
                    // Фіолетова пляма
                    Circle()
                        .fill(Color.meshTopLeft)
                        .blur(radius: 100)
                        .frame(width: proxy.size.width * 0.8)
                        .offset(x: -proxy.size.width * 0.2, y: -proxy.size.height * 0.1)
                    
                    // Рожева пляма
                    Circle()
                        .fill(Color.meshTopRight)
                        .blur(radius: 120)
                        .frame(width: proxy.size.width * 0.8)
                        .offset(x: proxy.size.width * 0.4, y: proxy.size.height * 0.1)
                    
                    // Блакитна пляма
                    Circle()
                        .fill(Color.meshBottom)
                        .blur(radius: 100)
                        .frame(width: proxy.size.width)
                        .offset(x: -proxy.size.width * 0.1, y: proxy.size.height * 0.5)
                }
                // ✨ МАГІЯ ТУТ: Збільшуємо прозорість, щоб було яскраво! ✨
                // Було 0.3 -> Стало 0.75 (тепер це насичений неон вночі)
                // Вдень залишаємо 0.65, бо на світлому фоні це виглядає добре
                .opacity(colorScheme == .dark ? 0.75 : 0.65)
            }
            .ignoresSafeArea()
        }
    }
}

// --- 2. АДАПТИВНЕ СКЛО (Liquid Glass) ---
struct LiquidGlassModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 24)
                    // Темне скло вночі, світле вдень
                    .fill(colorScheme == .dark ? Color.black.opacity(0.4) : Color.white.opacity(0.6))
            )
            .background(.ultraThinMaterial)
            .cornerRadius(24)
            // Тінь є тільки вдень, вночі ми її прибираємо
            .shadow(color: colorScheme == .dark ? .clear : .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

extension View {
    func liquidGlass() -> some View {
        self.modifier(LiquidGlassModifier())
    }
}

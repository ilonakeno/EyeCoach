import SwiftUI

struct TypewriterText: View {
    let text: String
    @State private var displayedText: String = ""
    @State private var timer: Timer? = nil
    
    var body: some View {
        Text(displayedText)
            .font(.system(size: 20, weight: .semibold)) // ‼️ Такий самий шрифт як у SpeechBubble
            .foregroundColor(.black)
            .multilineTextAlignment(.leading)
            .onAppear { startTyping() }
            .onChange(of: text) { _, _ in startTyping() }
    }
    
    func startTyping() {
        timer?.invalidate()
        displayedText = ""
        var charIndex = 0
        let chars = Array(text)
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { t in
            if charIndex < chars.count {
                displayedText.append(chars[charIndex])
                charIndex += 1
            } else {
                t.invalidate()
            }
        }
    }
}

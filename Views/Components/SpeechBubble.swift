//
//  SpeechBubble.swift
//  EyeGym
//
//  Created by Ilona Keno on 14.02.2026.
//

import SwiftUI

struct SpeechBubble: View {
    let text: String
    
    // Внутрішня логіка друкування
    @State private var displayedText: String = ""
    @State private var timer: Timer? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                // 1. НЕВИДИМИЙ ПОВНИЙ ТЕКСТ (для розміру)
                Text(text)
                    .font(.system(size: 18, weight: .medium)) // Трохи зменшив шрифт для гри
                    .foregroundColor(.clear)
                    .multilineTextAlignment(.leading)
                    .animation(nil, value: text)
                
                // 2. ТЕКСТ, ЩО ДРУКУЄТЬСЯ
                Text(displayedText)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.leading)
            }
            .padding(16) // Трохи менші відступи
            .background(Color.white)
            .cornerRadius(20)
            
            // ХВОСТИК
            Image(systemName: "arrowtriangle.down.fill")
                .resizable()
                .frame(width: 24, height: 14) // Трохи менший хвостик
                .foregroundColor(.white)
                .padding(.leading, 30)
                .offset(y: -2)
                .zIndex(-1)
        }
        .compositingGroup()
        .shadow(color: Color.black.opacity(0.15), radius: 10, y: 5)
        
        // Логіка друкування
        .onAppear { startTyping() }
        .onChange(of: text) { _, _ in startTyping() }
    }
    
    func startTyping() {
        timer?.invalidate()
        // Якщо текст короткий (підказка у грі) - друкуємо швидше
        let typingSpeed = text.count < 30 ? 0.02 : 0.03
        
        displayedText = ""
        var charIndex = 0
        let chars = Array(text)
        
        timer = Timer.scheduledTimer(withTimeInterval: typingSpeed, repeats: true) { t in
            if charIndex < chars.count {
                displayedText.append(chars[charIndex])
                charIndex += 1
            } else {
                t.invalidate()
            }
        }
    }
}

// Прев'ю для тестування самої хмаринки
#Preview {
    ZStack {
        Color.gray.opacity(0.2).ignoresSafeArea()
        SpeechBubble(text: "Put your head in the frame!")
            .frame(width: 200)
    }
}

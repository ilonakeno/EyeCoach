import Foundation
import AVFoundation

class SpeechManager {
    static let shared = SpeechManager()
    private let synthesizer = AVSpeechSynthesizer()
    
    func speak(text: String, language: String = "en-US") { // 🇬🇧 Британський акцент
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        
        // ✨ НАЛАШТУВАННЯ ГОЛОСУ ДІНО ✨
        utterance.rate = 0.52 // Трохи швидше
        utterance.pitchMultiplier = 1.3 // Вища тональність (робить голос дитячим/мультяшним)
        utterance.volume = 1.0
        
        synthesizer.speak(utterance)
    }
    
    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }
}

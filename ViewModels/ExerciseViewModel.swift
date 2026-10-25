import SwiftUI
import ARKit
import Combine
import UIKit
import AudioToolbox // 🔥 ДОДАНО ДЛЯ ЗВУКУ ПОМИЛКИ 🔥

enum CircleStage { case up, left, down, right }
enum HorizonStage { case start, right }
enum VerticalStage { case start, up }

enum Figure8Stage {
    case start      // Чекаємо першого руху
    case upRight    // 1. Вправо-Вгору ↗️
    case downRight  // 2. Вправо-Вниз ↘️
    case upLeft     // 3. Вліво-Вгору ↖️
    case downLeft   // 4. Вліво-Вниз ↙️
}

// 🔥 НОВЕ: Стан для вправи Blink and Focus 🔥
enum BlinkFocusState {
    case waiting
    case blinking
    case focusing
}

class ExerciseViewModel: ObservableObject {
    @Published var arManager = ARManager()
    
    @Published var currentLap = 0
    @Published var targetLaps = 5
    @Published var isCompleted = false
    @Published var feedbackMessage = "Get ready!"
    
    // 🔥 ДОДАНО ЗМІННІ ДЛЯ МАСАЖУ 🔥
    @Published var timeRemaining: Int = 30
    private var lastTimerUpdate: Date = Date()
    
    private var isEyesClosed = false
    @Published var circleStage: CircleStage = .up
    @Published var horizonStage: HorizonStage = .start
    @Published var verticalStage: VerticalStage = .start
    @Published var figure8Stage: Figure8Stage = .start
    
    // 🔥 НОВІ ЗМІННІ ДЛЯ НОВИХ ВПРАВ 🔥
    @Published var dinoWarningText: String? = nil
    @Published var blinkFocusPhaseText: String = ""
    @Published var blinkFocusState: BlinkFocusState = .waiting
    private var lastWarningTime: Date = Date.distantPast
    private var lastBlinkTimestamp: Date = Date()
    
    func startExercise(name: String) {
        arManager.start()
        resetGame()
        
        if name == "Blinking" {
            targetLaps = 10; feedbackMessage = "Blink your eyes!"
        } else if name == "Circle" {
            targetLaps = 10; circleStage = .up; feedbackMessage = "Look UP ⬆️"
        } else if name == "Horizon" {
            targetLaps = 10; horizonStage = .start; feedbackMessage = "Look Right ➡️"
        } else if name == "Vertical" {
            targetLaps = 10; verticalStage = .start; feedbackMessage = "Look UP ⬆️"
        } else if name == "Figure 8" {
            targetLaps = 5
            figure8Stage = .start
            feedbackMessage = "Look Up-Right ↗️"
        } else if name == "Massage" {
            // 🔥 СКИДАЄМО ТАЙМЕР НА СТАРТІ 🔥
            timeRemaining = 30
            lastTimerUpdate = Date()
            feedbackMessage = "Close your eyes!"
        }
        // 🔥 НОВЕ: ІНІЦІАЛІЗАЦІЯ НОВИХ ВПРАВ 🔥
        else if name == "Focus" || name == "Unfocus" {
            timeRemaining = 15
            lastTimerUpdate = Date()
            feedbackMessage = "Don't blink!"
            dinoWarningText = nil
        } else if name == "Blink and Focus" {
            currentLap = 0
            targetLaps = 3
            blinkFocusState = .waiting
            blinkFocusPhaseText = "Blink once to start!"
            dinoWarningText = nil
            lastTimerUpdate = Date()
        } else if name == "Zig Zag" || name == "Spiral" {
            timeRemaining = 24 // 6 проходів по 4 сек
            lastTimerUpdate = Date()
            feedbackMessage = "Follow the capsule!"
        }
    }
    
    func stopCamera() { arManager.pause() }
    
    func resetGame() {
        currentLap = 0; isCompleted = false; isEyesClosed = false; timeRemaining = 30
        circleStage = .up; horizonStage = .start; verticalStage = .start; figure8Stage = .start
        dinoWarningText = nil
    }
    
    func updateGameLogic(exerciseName: String) {
        guard !isCompleted, arManager.isFaceAligned else { return }
        
        if exerciseName == "Blinking" { checkBlinkingLogic() }
        else if exerciseName == "Circle" { checkCircleLogic() }
        else if exerciseName == "Horizon" { checkHorizonLogic() }
        else if exerciseName == "Vertical" { checkVerticalLogic() }
        else if exerciseName == "Figure 8" { checkFigure8Logic() }
        else if exerciseName == "Massage" { checkMassageLogic() } // 🔥 ВИКЛИК ЛОГІКИ МАСАЖУ 🔥
        
        // 🔥 НОВЕ: ВИКЛИК ЛОГІКИ ДЛЯ НОВИХ ВПРАВ 🔥
        else if exerciseName == "Focus" || exerciseName == "Unfocus" { checkFocusLogic() }
        else if exerciseName == "Blink and Focus" { checkBlinkAndFocusLogic() }
        else if exerciseName == "Zig Zag" || exerciseName == "Spiral" { checkVisualOnlyLogic() }
    }
    
    // 🔥 НОВА ФУНКЦІЯ: ЛОГІКА МАСАЖУ 🔥
    private func checkMassageLogic() {
        let threshold: Float = 0.75
        let eyesClosedNow = (arManager.blinkLeft > threshold && arManager.blinkRight > threshold)
        
        if eyesClosedNow {
            // Оновлюємо таймер, якщо пройшла секунда
            if Date().timeIntervalSince(lastTimerUpdate) >= 1.0 {
                timeRemaining -= 1
                lastTimerUpdate = Date()
                
                if timeRemaining <= 0 {
                    finishExercise()
                }
            }
        } else {
            // Якщо людина відкрила очі, просто оновлюємо таймстемп, щоб не віднімався час
            lastTimerUpdate = Date()
        }
    }

    private func checkBlinkingLogic() {
        let threshold: Float = 0.75
        let eyesClosedNow = (arManager.blinkLeft > threshold && arManager.blinkRight > threshold)
        if eyesClosedNow && !isEyesClosed { isEyesClosed = true; feedbackMessage = "Open..." }
        else if !eyesClosedNow && isEyesClosed { isEyesClosed = false; currentLap += 1; triggerHapticFeedback(); feedbackMessage = "Good! \(currentLap)/\(targetLaps)"; if currentLap >= targetLaps { finishExercise() } }
    }
    
    private func checkCircleLogic() {
        let t: Float = 0.25
        switch circleStage {
        case .up: if arManager.lookUp > t { triggerHapticFeedback(); circleStage = .left; feedbackMessage = "Look LEFT ⬅️" }
        case .left: if arManager.lookLeft > t { triggerHapticFeedback(); circleStage = .down; feedbackMessage = "Look DOWN ⬇️" }
        case .down: if arManager.lookDown > t { triggerHapticFeedback(); circleStage = .right; feedbackMessage = "Look RIGHT ➡️" }
        case .right: if arManager.lookRight > t { triggerHapticFeedback(); currentLap += 1; if currentLap >= targetLaps { finishExercise() } else { circleStage = .up; feedbackMessage = "Look UP ⬆️" } }
        }
    }
    
    private func checkHorizonLogic() {
        let threshold: Float = 0.2
        switch horizonStage {
        case .start: if arManager.lookRight > threshold { horizonStage = .right; triggerHapticFeedback(); feedbackMessage = "Now Look Left! ⬅️" }
        case .right: if arManager.lookLeft > threshold { currentLap += 1; triggerHapticFeedback(); if currentLap >= targetLaps { finishExercise() } else { horizonStage = .start; feedbackMessage = "Good! Right again. ➡️" } }
        }
    }

    private func checkVerticalLogic() {
        let threshold: Float = 0.2
        switch verticalStage {
        case .start: if arManager.lookUp > threshold { verticalStage = .up; triggerHapticFeedback(); feedbackMessage = "Now Look Down! ⬇️" }
        case .up: if arManager.lookDown > threshold { currentLap += 1; triggerHapticFeedback(); if currentLap >= targetLaps { finishExercise() } else { verticalStage = .start; feedbackMessage = "Good! Up again. ⬆️" } }
        }
    }

    private func checkFigure8Logic() {
        let t: Float = 0.15 // Поріг
        
        switch figure8Stage {
        case .start:
            if arManager.lookUpRight > t {
                figure8Stage = .upRight
                triggerHapticFeedback()
                feedbackMessage = "Now Down-Right ↘️"
            }
            
        case .upRight:
            if arManager.lookDownRight > t {
                figure8Stage = .downRight
                triggerHapticFeedback()
                feedbackMessage = "Now Up-Left ↖️"
            }
            
        case .downRight:
            if arManager.lookUpLeft > t {
                figure8Stage = .upLeft
                triggerHapticFeedback()
                feedbackMessage = "Now Down-Left ↙️"
            }
            
        case .upLeft:
            if arManager.lookDownLeft > t {
                figure8Stage = .downLeft
                triggerHapticFeedback()
                feedbackMessage = "Loop done! Up-Right ↗️"
            }
            
        case .downLeft:
            if arManager.lookUpRight > t {
                currentLap += 1
                triggerHapticFeedback()
                
                if currentLap >= targetLaps {
                    finishExercise()
                } else {
                    figure8Stage = .upRight
                    feedbackMessage = "Good! Down-Right ↘️"
                }
            }
        }
    }
    
    // =========================================================================
    // 🔥 НОВЕ: ЛОГІКА ДЛЯ FOCUS ТА UNFOCUS 🔥
    // =========================================================================
    private func checkFocusLogic() {
        let threshold: Float = 0.75
        let eyesClosedNow = (arManager.blinkLeft > threshold && arManager.blinkRight > threshold)
        let now = Date()
        
        // Перевіряємо чи закриті очі
        if eyesClosedNow {
            // Якщо минуло більше 3 секунд з минулого попередження - кричимо знову
            if now.timeIntervalSince(lastWarningTime) > 3.0 {
                triggerErrorFeedback()
                showDinoWarning("Open your eyes!")
                lastWarningTime = now
            }
        }
        
        // Віднімаємо таймер кожну секунду
        if now.timeIntervalSince(lastTimerUpdate) >= 1.0 {
            timeRemaining -= 1
            lastTimerUpdate = now
            
            if timeRemaining <= 0 {
                finishExercise()
            }
        }
    }
    
    // =========================================================================
    // 🔥 НОВЕ: ЛОГІКА ДЛЯ BLINK AND FOCUS (МАШИНА СТАНІВ) 🔥
    // =========================================================================
    private func checkBlinkAndFocusLogic() {
        let threshold: Float = 0.75
        let eyesClosedNow = (arManager.blinkLeft > threshold && arManager.blinkRight > threshold)
        let now = Date()
        
        switch blinkFocusState {
        case .waiting:
            // Чекаємо першого кліпання, щоб почати
            if eyesClosedNow {
                blinkFocusState = .blinking
                timeRemaining = 10
                lastTimerUpdate = now
                lastBlinkTimestamp = now
                blinkFocusPhaseText = "Blink fast!"
            }
            
        case .blinking:
            if eyesClosedNow {
                // Оновлюємо час останнього кліпання
                lastBlinkTimestamp = now
            } else {
                // Якщо очі відкриті більше 1 секунди - попереджаємо
                if now.timeIntervalSince(lastBlinkTimestamp) > 1.0 {
                    if now.timeIntervalSince(lastWarningTime) > 3.0 {
                        showDinoWarning("Keep blinking! Don't stop!")
                        lastWarningTime = now
                    }
                }
            }
            
            // Таймер для фази кліпання (10 сек)
            if now.timeIntervalSince(lastTimerUpdate) >= 1.0 {
                timeRemaining -= 1
                lastTimerUpdate = now
                if timeRemaining <= 0 {
                    blinkFocusState = .focusing
                    timeRemaining = 5
                    blinkFocusPhaseText = "Focus! Don't blink!"
                    triggerHapticFeedback() // Сигнал про зміну фази
                }
            }
            
        case .focusing:
            // Якщо людина кліпає у фазі фокусу - караємо
            if eyesClosedNow {
                if now.timeIntervalSince(lastWarningTime) > 3.0 {
                    triggerErrorFeedback()
                    showDinoWarning("Keep focus! Do not blink!")
                    lastWarningTime = now
                }
            }
            
            // Таймер для фази фокусу (5 сек)
            if now.timeIntervalSince(lastTimerUpdate) >= 1.0 {
                timeRemaining -= 1
                lastTimerUpdate = now
                if timeRemaining <= 0 {
                    currentLap += 1
                    
                    if currentLap >= targetLaps {
                        blinkFocusPhaseText = "Done!"
                        finishExercise()
                    } else {
                        // Повертаємось до кліпання
                        blinkFocusState = .blinking
                        timeRemaining = 10
                        blinkFocusPhaseText = "Blink fast again!"
                        lastBlinkTimestamp = now
                        triggerHapticFeedback()
                    }
                }
            }
        }
    }
    
    // =========================================================================
    // 🔥 НОВЕ: ЛОГІКА ДЛЯ ВІЗУАЛЬНИХ ВПРАВ (Zig Zag, Spiral) 🔥
    // =========================================================================
    private func checkVisualOnlyLogic() {
        let now = Date()
        if now.timeIntervalSince(lastTimerUpdate) >= 1.0 {
            timeRemaining -= 1
            lastTimerUpdate = now
            if timeRemaining <= 0 {
                finishExercise()
            }
        }
    }
    
    // =========================================================================
    // 🔥 НОВЕ: ДОПОМІЖНІ ФУНКЦІЇ ДЛЯ ПОМИЛОК 🔥
    // =========================================================================
    private func showDinoWarning(_ text: String) {
        dinoWarningText = text
        // Ховаємо Діно через 2.5 секунди
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            if self.dinoWarningText == text {
                self.dinoWarningText = nil
            }
        }
    }
    
    private func triggerErrorFeedback() {
        // Вібрація помилки
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
        // Системний звук "Бз-Бз" (якщо телефон не в беззвучному режимі)
        AudioServicesPlaySystemSound(1006)
    }
    
    private func triggerHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium); generator.impactOccurred()
    }
    
    private func finishExercise() {
        isCompleted = true; triggerHapticFeedback(); feedbackMessage = "Exercise Completed! 🎉"
    }
}

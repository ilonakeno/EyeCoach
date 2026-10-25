//
//  WorkoutSessionView.swift
//  EyeGym
//
//  Created by Ilona Keno on 26.02.2026.
//

import SwiftUI

struct WorkoutSessionView: View {
    var exerciseQueue: [String]
    @Environment(\.dismiss) var dismiss
    
    @State private var currentIndex: Int = 0
    @State private var showingInstruction: Bool = false
    
    // Ця змінна контролює, чи казатиме Діно "Hi, I am Dino!"
    @State private var isFirstTutorialInSession: Bool = true
    
    var currentExercise: String {
        guard currentIndex < exerciseQueue.count else { return "" }
        return exerciseQueue[currentIndex]
    }
    
    var isLastExercise: Bool {
        currentIndex == exerciseQueue.count - 1
    }
    
    var body: some View {
        Group {
            if currentExercise.isEmpty {
                Color.white.ignoresSafeArea()
            } else if showingInstruction {
                // ПОКАЗУЄМО ІНСТРУКЦІЮ
                InstructionView(
                    exerciseName: currentExercise,
                    isFirstInSession: isFirstTutorialInSession,
                    onFinishInstruction: {
                        // Після завершення першої інструкції, наступні вже не будуть вітатися
                        isFirstTutorialInSession = false
                        showingInstruction = false
                    }
                )
                // Завжди перестворюємо View для нової вправи
                .id("instruction_\(currentExercise)")
            } else {
                // ПОКАЗУЄМО ВПРАВУ
                ExerciseView(
                    exerciseName: currentExercise,
                    isLastExercise: isLastExercise,
                    onNextExercise: {
                        if isLastExercise {
                            dismiss() // Закриваємо тренування
                        } else {
                            currentIndex += 1
                            checkIfInstructionNeeded() // Перевіряємо, чи треба інструкція для наступної
                        }
                    },
                    onReplayInstruction: {
                        // Примусовий запуск інструкції по кнопці Tutorial
                        showingInstruction = true
                    }
                )
                // Завжди перестворюємо View для нової вправи (скидає таймери і стан)
                .id("exercise_\(currentExercise)")
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            checkIfInstructionNeeded()
        }
    }
    
    // Перевірка, чи бачив користувач інструкцію до цієї вправи
    private func checkIfInstructionNeeded() {
        let hasSeen = UserDefaults.standard.bool(forKey: "hasSeen_\(currentExercise)")
        if !hasSeen {
            showingInstruction = true
        } else {
            showingInstruction = false
        }
    }
}

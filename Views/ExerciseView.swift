import SwiftUI
import SwiftData
import ARKit
import Combine
import UIKit // 🔥 ДОДАНО ДЛЯ ВІБРАЦІЇ 🔥

struct ExerciseView: View {
    @EnvironmentObject var userManager: UserManager
    @StateObject private var viewModel = ExerciseViewModel()
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var context
    
    @State var exerciseName: String
    
    var exerciseQueue: [String] = []
    @State private var remainingQueue: [String] = []
    
    // 🔥 МАГІЯ СИНХРОНІЗАЦІЇ ЗВУКУ 🔥
    @AppStorage("voiceGuidance") var isSoundOn: Bool = false
    
    // 🔥 ДОДАНО: МАГІЯ СИНХРОНІЗАЦІЇ РОЗМІРУ ТЕКСТУ 🔥
    @AppStorage("textSizeMultiplier") var textSizeMultiplier: Double = 1.0
    
    var onReplayInstruction: (() -> Void)? = nil
    
    let gameTimer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 1. КАМЕРА (Найнижчий шар)
                ARCameraView(arManager: viewModel.arManager).ignoresSafeArea()
                
                // 2. РАМКА
                if !viewModel.isCompleted {
                    VStack {
                        Spacer()
                        Ellipse()
                            .stroke(Color.white, style: StrokeStyle(lineWidth: 4, dash: [15, 10]))
                            .frame(width: 280, height: 400)
                            .opacity(0.8)
                            .shadow(radius: 5)
                            .padding(.bottom, 50)
                        Spacer()
                    }
                }
                
                // 3. ІГРОВИЙ ІНТЕРФЕЙС
                gameInterface(geometry: geometry)
                
                // 4. ДІНОЗАВР-ПІДКАЗКА
                if !viewModel.arManager.isFaceAligned && !viewModel.isCompleted && viewModel.currentLap == 0 {
                    VStack {
                        Spacer()
                        HStack(alignment: .bottom, spacing: 0) {
                            Image("dino")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 180)
                                .offset(x: -5, y: 150)
                            
                            // 🔥 КАСТОМНИЙ ТЕКСТ ДЛЯ МАСАЖУ 🔥
                            SpeechBubble(text: exerciseName == "Massage" ? "Put your head in the frame\nand close your eyes!" : "Put your head in the frame!")
                                .frame(width: 180)
                                // 🔥 ЗАСТОСОВАНО МАСШТАБУВАННЯ ДО БУЛЬБАШКИ 🔥
                                .scaleEffect(textSizeMultiplier)
                                .offset(x: -130, y: -165)
                            
                            Spacer()
                        }
                        .padding(.leading, -10)
                        .padding(.bottom, 30)
                    }
                    .transition(.move(edge: .leading).combined(with: .opacity))
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: viewModel.arManager.isFaceAligned)
                }
                
                // 5. ЕКРАН УСПІХУ
                if viewModel.isCompleted {
                    ZStack {
                        LinearGradient(
                            colors: [Color(red: 0.85, green: 0.8, blue: 1.0), .white],
                            startPoint: .top,
                            endPoint: .center
                        )
                        .ignoresSafeArea()
                        
                        ZStack {
                            Image("dino")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 239.22, height: 466.06)
                                .clipped()
                                .offset(x: -10, y: 150)
                            
                            SpeechBubble(text: "Great! Let's move on!")
                                .frame(width: 220)
                                // 🔥 ЗАСТОСОВАНО МАСШТАБУВАННЯ ДО БУЛЬБАШКИ 🔥
                                .scaleEffect(textSizeMultiplier)
                                .offset(x: -20, y: -100)
                            
                            Button(action: {
                                if userManager.isUserLoggedIn {
                                    context.insert(UserSession(exerciseName: exerciseName, isCompleted: true))
                                } else {
                                    userManager.triggerRegistration()
                                }
                                
                                if !remainingQueue.isEmpty {
                                    remainingQueue.removeFirst()
                                }
                                
                                if let nextExercise = remainingQueue.first {
                                    withAnimation {
                                        exerciseName = nextExercise
                                        viewModel.isCompleted = false
                                        viewModel.currentLap = 0
                                        viewModel.startExercise(name: nextExercise)
                                    }
                                } else {
                                    dismiss()
                                }
                            }) {
                                Text(remainingQueue.count > 1 ? "Next" : "Finish")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(width: 99, height: 54)
                                    .background(Color(red: 0.38, green: 0.33, blue: 0.96))
                                    .cornerRadius(14)
                                    .shadow(color: Color(red: 0.38, green: 0.33, blue: 0.96).opacity(0.3), radius: 10, y: 5)
                            }
                            .offset(x: 110, y: 100)
                        }
                    }
                    .zIndex(5)
                }
                
                // 6. ВЕРХНЯ ПАНЕЛЬ
                VStack {
                    ZStack(alignment: .top) {
                        Text(exerciseName)
                            // 🔥 ЗАСТОСОВАНО МАСШТАБУВАННЯ ДО НАЗВИ ВПРАВИ 🔥
                            .font(.system(size: 24 * textSizeMultiplier, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(radius: 5)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 70)
                            .padding(.top, 10)
                        
                        HStack(alignment: .top) {
                            Button(action: { dismiss() }) {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 50, height: 50)
                                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                                    .overlay(
                                        Image(systemName: "xmark")
                                            .font(.system(size: 17, weight: .semibold))
                                            .foregroundColor(.primary)
                                    )
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 12) {
                                if onReplayInstruction != nil && !viewModel.isCompleted {
                                    Button(action: {
                                        viewModel.stopCamera()
                                        onReplayInstruction?()
                                    }) {
                                        HStack(spacing: 4) {
                                            Text("Tutorial")
                                                .font(.subhead)
                                                .bold()
                                            Image(systemName: "questionmark.circle.fill")
                                                .font(.system(size: 20))
                                        }
                                        .foregroundColor(.primary)
                                        .padding(.horizontal, 16)
                                        .frame(height: 50)
                                        .background(Capsule().fill(.ultraThinMaterial))
                                        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                                    }
                                }
                                
                                if !viewModel.isCompleted {
                                    Button(action: {
                                        isSoundOn.toggle()
                                        if !isSoundOn {
                                            SpeechManager.shared.stop()
                                        } else {
                                            SpeechManager.shared.speak(text: "Sound is on")
                                        }
                                    }) {
                                        Circle()
                                            .fill(.ultraThinMaterial)
                                            .frame(width: 50, height: 50)
                                            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                                            .overlay(
                                                Image(systemName: isSoundOn ? "speaker.wave.2.fill" : "speaker.slash.fill")
                                                    .font(.system(size: 22))
                                                    .foregroundColor(isSoundOn ? Color(hex: "6155F5") : .primary)
                                            )
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 10)
                    
                    Spacer()
                }
                .zIndex(100)
            }
        }
        .onAppear {
            if !exerciseQueue.isEmpty && remainingQueue.isEmpty {
                remainingQueue = exerciseQueue
            }
            if let first = remainingQueue.first {
                exerciseName = first
            }
            viewModel.startExercise(name: exerciseName)
            
            // 🔥 ОЗВУЧКА НА СТАРТІ (СПЕЦИФІЧНА ДЛЯ МАСАЖУ) 🔥
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if isSoundOn {
                    if !viewModel.arManager.isFaceAligned {
                        SpeechManager.shared.speak(text: exerciseName == "Massage" ? "Put your head in the frame and close your eyes!" : "Put your head in the frame!")
                    } else {
                        SpeechManager.shared.speak(text: exerciseName == "Massage" ? "Close your eyes to start the timer!" : "Let's start!")
                    }
                }
            }
        }
        .onChange(of: viewModel.arManager.isFaceAligned) { aligned in
            if aligned && !viewModel.isCompleted && isSoundOn {
                SpeechManager.shared.speak(text: exerciseName == "Massage" ? "Perfect! Close your eyes to begin." : "Perfect! Follow the targets.")
            }
        }
        .onChange(of: viewModel.isCompleted) { completed in
            if completed {
                // 🔥 ВІБРАЦІЯ БЗ-БЗ-БЗ КОЛИ МАСАЖ ЗАВЕРШЕНО 🔥
                if exerciseName == "Massage" {
                    let impact = UIImpactFeedbackGenerator(style: .heavy)
                    impact.impactOccurred()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { impact.impactOccurred() }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { impact.impactOccurred() }
                }
                
                if isSoundOn {
                    SpeechManager.shared.speak(text: "Great! Let's move on!")
                }
            }
        }
        .onDisappear {
            viewModel.stopCamera()
            SpeechManager.shared.stop()
        }
        .onReceive(gameTimer) { _ in
            viewModel.updateGameLogic(exerciseName: exerciseName)
        }
    }
    
    @ViewBuilder
    func gameInterface(geometry: GeometryProxy) -> some View {
        ZStack {
            if !viewModel.isCompleted {
                VStack {
                    // 🔥 ЛОГІКА ТАЙМЕРА ДЛЯ МАСАЖУ 🔥
                    if exerciseName == "Massage" {
                        Text("\(viewModel.timeRemaining) s")
                            .font(.system(size: 60 * textSizeMultiplier, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(radius: 5)
                            .padding(.top, 80)
                    } else {
                        Text("\(viewModel.currentLap) / \(viewModel.targetLaps)")
                            .font(.system(size: 60 * textSizeMultiplier, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(radius: 5)
                            .padding(.top, 80)
                    }
                    Spacer()
                }
            }
            
            if exerciseName == "Figure 8" {
                StatusCircle(isActive: viewModel.figure8Stage == .start || viewModel.figure8Stage == .upRight || viewModel.figure8Stage == .downLeft, icon: "arrow.up.right")
                    .position(x: geometry.size.width/2 + 100, y: geometry.size.height/2 - 120)
                StatusCircle(isActive: viewModel.figure8Stage == .downRight, icon: "arrow.down.right")
                    .position(x: geometry.size.width/2 + 100, y: geometry.size.height/2 + 120)
                StatusCircle(isActive: viewModel.figure8Stage == .upLeft, icon: "arrow.up.left")
                    .position(x: geometry.size.width/2 - 100, y: geometry.size.height/2 - 120)
                StatusCircle(isActive: viewModel.figure8Stage == .downLeft, icon: "arrow.down.left")
                    .position(x: geometry.size.width/2 - 100, y: geometry.size.height/2 + 120)
                
            } else if exerciseName == "Circle" {
                StatusCircle(isActive: viewModel.circleStage == .up, icon: "arrow.up")
                    .position(x: geometry.size.width/2, y: geometry.size.height/2 - 130)
                StatusCircle(isActive: viewModel.circleStage == .right, icon: "arrow.right")
                    .position(x: geometry.size.width/2 + 130, y: geometry.size.height/2)
                StatusCircle(isActive: viewModel.circleStage == .down, icon: "arrow.down")
                    .position(x: geometry.size.width/2, y: geometry.size.height/2 + 130)
                StatusCircle(isActive: viewModel.circleStage == .left, icon: "arrow.left")
                    .position(x: geometry.size.width/2 - 130, y: geometry.size.height/2)
                
            } else if exerciseName == "Horizon" {
                StatusCircle(isActive: viewModel.horizonStage == .start, icon: "arrow.right")
                    .position(x: geometry.size.width - 80, y: geometry.size.height / 2)
                StatusCircle(isActive: viewModel.horizonStage == .right, icon: "arrow.left")
                    .position(x: 80, y: geometry.size.height / 2)
                
            } else if exerciseName == "Vertical" {
                StatusCircle(isActive: viewModel.verticalStage == .start, icon: "arrow.up")
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2 - 150)
                StatusCircle(isActive: viewModel.verticalStage == .up, icon: "arrow.down")
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2 + 150)
            }
            
            if !viewModel.isCompleted {
                Button(action: {
                    // 🔥 СИМУЛЯЦІЯ ДЛЯ МАСАЖУ 🔥
                    if exerciseName == "Massage" {
                        viewModel.timeRemaining -= 5 // Швидко промотуємо час
                        if viewModel.timeRemaining <= 0 {
                            viewModel.isCompleted = true
                        }
                    } else {
                        viewModel.currentLap += 1
                        if viewModel.currentLap >= viewModel.targetLaps {
                            viewModel.isCompleted = true
                        }
                    }
                }) {
                    Text("Tap to simulate")
                        .font(.caption)
                        .padding(10)
                        .background(Color.blue)
                        .cornerRadius(8)
                        .foregroundColor(.white)
                }
                .padding(.top, 200)
            }
        }
    }
}

struct StatusCircle: View {
    var isActive: Bool
    var icon: String
    var body: some View {
        ZStack {
            Circle()
                .fill(isActive ? Color(hex: "6155F5") : Color.white.opacity(0.2))
                .frame(width: 70, height: 70)
                .overlay(
                    Circle().stroke(Color.white, lineWidth: isActive ? 3 : 1)
                        .opacity(isActive ? 1 : 0.5)
                )
                .shadow(color: isActive ? Color(hex: "6155F5").opacity(0.8) : .clear, radius: 15)
                .scaleEffect(isActive ? 1.2 : 1.0)
                .animation(.spring(), value: isActive)
            
            Image(systemName: icon)
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(.white)
                .opacity(isActive ? 1.0 : 0.5)
        }
    }
}

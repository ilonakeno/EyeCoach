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
    
    // 🔥 НОВЕ: Команди від WorkoutSessionView 🔥
    var isLastExercise: Bool = false
    var onNextExercise: () -> Void = {}
    
    @AppStorage("voiceGuidance") var isSoundOn: Bool = false
    @AppStorage("textSizeMultiplier") var textSizeMultiplier: Double = 1.0
    
    var onReplayInstruction: (() -> Void)? = nil
    
    let gameTimer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    @State private var visualProgress: CGFloat = 0.0
    @State private var showVisualIntro: Bool = false
    
    var isVisualOnly: Bool {
        return exerciseName == "Zig Zag" || exerciseName == "Spiral"
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 1. КАМЕРА (Найнижчий шар)
                ARCameraView(arManager: viewModel.arManager).ignoresSafeArea()
                
                // Фіолетовий фон для Unfocus
                if exerciseName == "Unfocus" && !viewModel.isCompleted {
                    RadialGradient(
                        gradient: Gradient(colors: [Color(hex: "6155F5").opacity(0.4), Color(hex: "3A2D8A")]),
                        center: .center,
                        startRadius: 10,
                        endRadius: 500
                    )
                    .ignoresSafeArea()
                    
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 100, height: 100)
                        .blur(radius: 40)
                }
                
                // 2. РАМКА
                if !viewModel.isCompleted && (!isVisualOnly || showVisualIntro) {
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
                
                // 4. ДІНОЗАВР-ПІДКАЗКА (ДЛЯ ЗВИЧАЙНИХ ВПРАВ)
                if !isVisualOnly && !viewModel.arManager.isFaceAligned && !viewModel.isCompleted && viewModel.currentLap == 0 {
                    VStack {
                        Spacer()
                        HStack(alignment: .bottom, spacing: 0) {
                            Image("dino")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 180)
                                .offset(x: -5, y: 150)
                            
                            SpeechBubble(text: exerciseName == "Massage" ? "Put your head in the frame\nand close your eyes!" : "Put your head in the frame!")
                                .frame(width: 180)
                                .scaleEffect(CGFloat(textSizeMultiplier))
                                .offset(x: -130, y: -165)
                            
                            Spacer()
                        }
                        .padding(.leading, -10)
                        .padding(.bottom, 30)
                    }
                    .transition(.move(edge: .leading).combined(with: .opacity))
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: viewModel.arManager.isFaceAligned)
                }
                
                // ДІНО-ПІДКАЗКА ДЛЯ ЗИГЗАГУ/СПІРАЛІ (ПЕРЕД ПОЧАТКОМ НА 2 СЕК)
                if isVisualOnly && showVisualIntro && !viewModel.isCompleted {
                    VStack {
                        Spacer()
                        HStack(alignment: .bottom, spacing: 0) {
                            Image("dino")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 180)
                                .offset(x: -5, y: 150)
                            
                            SpeechBubble(text: "Follow the capsule!")
                                .frame(width: 200)
                                .scaleEffect(CGFloat(textSizeMultiplier))
                                .offset(x: -130, y: -165)
                            
                            Spacer()
                        }
                        .padding(.leading, -10)
                        .padding(.bottom, 30)
                    }
                    .transition(.move(edge: .leading).combined(with: .opacity))
                    .zIndex(21)
                }
                
                // ДІНО-ПОПЕРЕДЖЕННЯ ПРО ПОМИЛКУ
                if let warningText = viewModel.dinoWarningText {
                    VStack {
                        Spacer()
                        HStack(alignment: .bottom, spacing: 0) {
                            Image("dino")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 150)
                                .offset(y: 100)
                            
                            SpeechBubble(text: warningText)
                                .frame(width: 220)
                                .scaleEffect(CGFloat(textSizeMultiplier))
                                .offset(x: -110, y: -120)
                            
                            Spacer()
                        }
                        .padding(.leading, -20)
                        .padding(.bottom, 50)
                    }
                    .transition(.move(edge: .leading).combined(with: .opacity))
                    .zIndex(20)
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
                                .scaleEffect(CGFloat(textSizeMultiplier))
                                .offset(x: -20, y: -100)
                            
                            Button(action: {
                                if userManager.isUserLoggedIn {
                                    context.insert(UserSession(exerciseName: exerciseName, isCompleted: true))
                                    // 🔥 ДОДАНО ПІДРАХУНОК СТРІКУ 🔥
                                    userManager.addExerciseCompleted()
                                } else {
                                    userManager.triggerRegistration()
                                }
                                onNextExercise() // Кажемо WorkoutSessionView перемикати
                            }) {
                                Text(isLastExercise ? "Finish" : "Next")
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
                            .font(.system(size: CGFloat(24.0 * textSizeMultiplier), weight: .bold))
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
            .onAppear {
                viewModel.startExercise(name: exerciseName)
                
                if isVisualOnly {
                    triggerVisualExercise(for: exerciseName)
                } else {
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
            }
        }
        .onChange(of: viewModel.arManager.isFaceAligned) { aligned in
            if aligned && !viewModel.isCompleted && isSoundOn && !isVisualOnly {
                SpeechManager.shared.speak(text: exerciseName == "Massage" ? "Perfect! Close your eyes to begin." : "Perfect! Follow the targets.")
            }
        }
        .onChange(of: viewModel.isCompleted) { completed in
            if completed {
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
    
    func triggerVisualExercise(for name: String) {
        showVisualIntro = true
        visualProgress = 0.0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if isSoundOn && exerciseName == name && !viewModel.isCompleted {
                SpeechManager.shared.speak(text: "Follow the capsule!")
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            if exerciseName == name && !viewModel.isCompleted {
                withAnimation { showVisualIntro = false }
                startVisualAnimations()
            }
        }
    }
    
    func startVisualAnimations() {
        let passDuration = 15.0 // Плавні 10 секунд на прохід
        let totalPasses = 6
        
        withAnimation(.easeInOut(duration: passDuration).repeatCount(totalPasses, autoreverses: true)) {
            visualProgress = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + (passDuration * Double(totalPasses))) {
            if isVisualOnly && !viewModel.isCompleted { viewModel.isCompleted = true }
        }
    }
    
    @ViewBuilder
    func gameInterface(geometry: GeometryProxy) -> some View {
        ZStack {
            if !viewModel.isCompleted {
                VStack {
                    if exerciseName == "Massage" || exerciseName == "Focus" || exerciseName == "Unfocus" || exerciseName == "Blink and Focus" {
                        Text("\(viewModel.timeRemaining) s")
                            .font(.system(size: CGFloat(60.0 * textSizeMultiplier), weight: .bold))
                            .foregroundColor(.white)
                            .shadow(radius: 5)
                            .padding(.top, 80)
                        
                    } else if !isVisualOnly {
                        Text("\(viewModel.currentLap) / \(viewModel.targetLaps)")
                            .font(.system(size: CGFloat(60.0 * textSizeMultiplier), weight: .bold))
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
                    
            } else if exerciseName == "Zig Zag" {
                // 🔥 ІДЕАЛЬНЕ ВИРІВНЮВАННЯ ЗИГЗАГУ (ЧЕРЕЗ ZSTACK) 🔥
                ZStack {
                    ZigZagShape()
                        .stroke(Color(hex: "6155F5"), style: StrokeStyle(lineWidth: 8, lineCap: .round, dash: [10, 15]))
                    
                    LiquidGlassCapsule()
                        .modifier(ZigZagAnimator(progress: visualProgress, size: geometry.size))
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                
            } else if exerciseName == "Spiral" {
                // 🔥 ІДЕАЛЬНЕ ВИРІВНЮВАННЯ СПІРАЛІ (ЧЕРЕЗ ZSTACK) 🔥
                ZStack {
                    SpiralShape(loops: 3)
                        .stroke(Color(hex: "6155F5"), style: StrokeStyle(lineWidth: 8, lineCap: .round, dash: [10, 15]))
                        .frame(width: 420, height: 420)
                    
                    LiquidGlassCapsule()
                        .modifier(SpiralAnimator(progress: visualProgress, size: CGSize(width: 420, height: 420), loops: 3))
                }
                .position(x: geometry.size.width / 2 + 15, y: geometry.size.height / 2)
                    
            } else if exerciseName == "Focus" {
                Circle()
                    .fill(Color(hex: "6155F5"))
                    .frame(width: 30, height: 30)
                    .overlay(Circle().stroke(Color.white, lineWidth: 3))
                    .shadow(color: Color(hex: "6155F5").opacity(0.8), radius: 10)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
        }
    }
}

// ====================================================================
// 🔥 ВСІ СТРУКТУРИ ТЕПЕР ТУТ І ТІЛЬКИ ТУТ 🔥
// ====================================================================

struct ZigZagAnimator: AnimatableModifier {
    var progress: CGFloat
    var size: CGSize
    
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }
    
    func body(content: Content) -> some View {
        let pts = [
            CGPoint(x: size.width * 0.2, y: size.height * 0.1),
            CGPoint(x: size.width * 0.8, y: size.height * 0.26),
            CGPoint(x: size.width * 0.2, y: size.height * 0.42),
            CGPoint(x: size.width * 0.8, y: size.height * 0.58),
            CGPoint(x: size.width * 0.2, y: size.height * 0.74),
            CGPoint(x: size.width * 0.8, y: size.height * 0.9)
        ]
        let totalSegments = CGFloat(pts.count - 1)
        let scaledProgress = max(0, min(1, progress)) * totalSegments
        let segmentIndex = min(Int(scaledProgress), pts.count - 2)
        let segmentProgress = scaledProgress - CGFloat(segmentIndex)
        
        let p1 = pts[segmentIndex]
        let p2 = pts[segmentIndex + 1]
        
        let currentPos = CGPoint(
            x: p1.x + (p2.x - p1.x) * segmentProgress,
            y: p1.y + (p2.y - p1.y) * segmentProgress
        )
        let currentRot = atan2(p2.y - p1.y, p2.x - p1.x) * 180.0 / .pi - 90.0
        
        return content
            .rotationEffect(Angle(degrees: Double(currentRot)))
            // 🔥 РАХУЄМО ВІД ЦЕНТРУ РАМКИ 🔥
            .offset(x: currentPos.x - size.width / 2, y: currentPos.y - size.height / 2)
    }
}

struct SpiralAnimator: AnimatableModifier {
    var progress: CGFloat
    var size: CGSize
    var loops: Int
    
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }
    
    func body(content: Content) -> some View {
        let maxRadius = min(size.width, size.height) / 2
        let currentRadius = maxRadius * progress
        let currentAngle = Double(progress) * Double(loops) * 360.0
        
        return content
            .offset(y: -currentRadius)
            .rotationEffect(Angle(degrees: currentAngle))
    }
}

struct ZigZagShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let pts = [
            CGPoint(x: rect.width * 0.2, y: rect.height * 0.1),
            CGPoint(x: rect.width * 0.8, y: rect.height * 0.26),
            CGPoint(x: rect.width * 0.2, y: rect.height * 0.42),
            CGPoint(x: rect.width * 0.8, y: rect.height * 0.58),
            CGPoint(x: rect.width * 0.2, y: rect.height * 0.74),
            CGPoint(x: rect.width * 0.8, y: rect.height * 0.9)
        ]
        path.move(to: pts[0])
        for i in 1..<pts.count { path.addLine(to: pts[i]) }
        return path
    }
}

struct LiquidGlassCapsule: View {
    var body: some View {
        ZStack {
            Capsule()
                .fill(Color.white.opacity(0.3))
                .background(Capsule().fill(.ultraThinMaterial))
                .overlay(
                    Capsule()
                        .stroke(LinearGradient(colors: [.white, .white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2)
                )
                .shadow(color: Color(hex: "6155F5").opacity(0.5), radius: 10, x: 0, y: 5)
            
            Capsule()
                .fill(Color.white.opacity(0.8))
                .frame(width: 4, height: 30)
        }
        .frame(width: 30, height: 60)
    }
}

struct SpiralShape: Shape {
    var loops: Int
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let maxRadius = min(rect.width, rect.height) / 2
        path.move(to: center)
        let maxAngle = Double.pi * 2.0 * Double(loops)
        for angle in stride(from: 0.0, through: maxAngle, by: 0.1) {
            let progress = angle / maxAngle
            let radius = maxRadius * CGFloat(progress)
            let x = center.x + radius * CGFloat(sin(angle))
            let y = center.y - radius * CGFloat(cos(angle))
            path.addLine(to: CGPoint(x: x, y: y))
        }
        return path
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

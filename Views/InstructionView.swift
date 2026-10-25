import SwiftUI

struct InstructionView: View {
    var exerciseName: String
    var isFirstInSession: Bool = true
    var onFinishInstruction: () -> Void
    
    var skipIntro: Bool = false
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var userManager: UserManager
    
    @AppStorage("voiceGuidance") var isSoundOn: Bool = true
    @AppStorage("textSizeMultiplier") var textSizeMultiplier: Double = 1.0
    
    // Етапи сценарію
    @State private var step: Int = 0
    @State private var dinoText: String = ""
    @State private var showStartButton = false
    @State private var isDinoBlinking = false
    @State private var dinoOffsetY: CGFloat = 50
    
    @State private var isAnimationRunning = false
    @State private var demoDirection: String = "dino"
    
    // Візуальні ефекти демонстрації
    @State private var visualDemoProgress: CGFloat = 0.0
    
    @StateObject private var arManager = ARManager()
    
    var isVisualOnly: Bool {
        return exerciseName == "Zig Zag" || exerciseName == "Spiral"
    }
    
    var body: some View {
        ZStack {
            // ==========================================
            // ШАР 1: ФОН
            // ==========================================
            Group {
                if step == 0 {
                    AnimatedIntroBackground().transition(.opacity)
                } else {
                    ARCameraView(arManager: arManager)
                }
                
                if step > 0 && exerciseName == "Unfocus" {
                    RadialGradient(
                        gradient: Gradient(colors: [Color(hex: "6155F5").opacity(0.4), Color(hex: "3A2D8A")]),
                        center: .center,
                        startRadius: 10,
                        endRadius: 500
                    )
                    .transition(.opacity)
                }
            }
            .ignoresSafeArea()
            
            // ==========================================
            // ШАР 2: ЦЕНТРАЛЬНИЙ КОНТЕНТ (ДІНО, РАМКИ, ДЕМО)
            // 🔥 Жодних '.clipped()'! Ноги будуть цілі 🔥
            // ==========================================
            ZStack {
                // ДІНОЗАВР
                dinoLayer
                
                // РАМКА ДЛЯ ОБЛИЧЧЯ (для невізуальних вправ)
                if step > 0 && !isVisualOnly && exerciseName != "Focus" {
                    VStack {
                        Spacer()
                        Ellipse()
                            .stroke(
                                Color(hex: "6155F5"),
                                style: StrokeStyle(lineWidth: 14, lineCap: .round, lineJoin: .round, dash: [0.1, 20])
                            )
                            .frame(width: 300, height: 420)
                            .padding(.bottom, 60)
                        Spacer()
                    }
                }
                
                // ДЕМОНСТРАЦІЯ ЛІНІЙ (Зигзаг / Спіраль)
                visualDemoLayer
                
                // БУЛЬБАШКА ТА КНОПКА START
                uiOverlayLayer
            }
            
            // ==========================================
            // ШАР 3: СТАТИЧНИЙ ІНТЕРФЕЙС (КНОПКИ)
            // 🔥 Завжди на місці, незалежно від розміру Діно 🔥
            // ==========================================
            VStack {
                topBar
                Spacer()
                skipButtonLayer
            }
            .padding(.top, 10)
        }
        .onAppear {
            setupInstruction()
        }
        .onDisappear {
            arManager.pause()
            SpeechManager.shared.stop()
        }
        .onChange(of: dinoText) { newValue in
            if isSoundOn && !newValue.isEmpty {
                SpeechManager.shared.speak(text: newValue)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    // MARK: - Subviews
    
    var topBar: some View {
        ZStack {
            // Назва вправи по центру
            HStack {
                Spacer()
                ZStack {
                    if step == 0 {
                        Ellipse()
                            .fill(Color(hex: "6155F5").opacity(0.8))
                            .frame(width: 160, height: 40)
                            .blur(radius: 50)
                            .offset(y: -10)
                    }
                    Text(exerciseName)
                        .font(.system(size: 24 * textSizeMultiplier, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: step == 0 ? .clear : .black.opacity(0.3), radius: 2)
                }
                Spacer()
            }

            // Кнопки з боків
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(step == 0 ? Color(hex: "727272") : .white)
                        .frame(width: 44, height: 44)
                        .background(step == 0 ? Color.gray.opacity(0.16) : Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
                
                Spacer()
                
                Button(action: toggleSound) {
                    Image(systemName: isSoundOn ? "speaker.wave.2.fill" : "speaker.slash.fill")
                        .font(.system(size: 22))
                        .foregroundColor(isSoundOn ? (step == 0 ? Color(hex: "6155F5") : .white) : .gray)
                        .frame(width: 50, height: 50)
                        .background(step == 0 ? Color.gray.opacity(0.16) : Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, 22)
    }
    
    @ViewBuilder
    var visualDemoLayer: some View {
        if step == 4 && isVisualOnly {
            GeometryReader { geometry in
                if exerciseName == "Zig Zag" {
                    ZStack {
                        ZigZagShape()
                            .stroke(Color(hex: "6155F5"), style: StrokeStyle(lineWidth: 8, lineCap: .round, dash: [10, 15]))
                        LiquidGlassCapsule()
                            .modifier(ZigZagAnimator(progress: visualDemoProgress, size: geometry.size))
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                        
                } else if exerciseName == "Spiral" {
                    ZStack {
                        SpiralShape(loops: 3)
                            .stroke(Color(hex: "6155F5"), style: StrokeStyle(lineWidth: 8, lineCap: .round, dash: [10, 15]))
                            .frame(width: 420, height: 420)
                        LiquidGlassCapsule()
                            .modifier(SpiralAnimator(progress: visualDemoProgress, size: CGSize(width: 420, height: 420), loops: 3))
                    }
                    .position(x: geometry.size.width / 2 + 15, y: geometry.size.height / 2)
                }
            }
        } else if step == 3 && exerciseName == "Focus" {
            GeometryReader { geometry in
                Circle()
                    .fill(Color(hex: "6155F5"))
                    .frame(width: 30, height: 30)
                    .overlay(Circle().stroke(Color.white, lineWidth: 3))
                    .shadow(color: Color(hex: "6155F5").opacity(0.8), radius: 10)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
        }
    }
    
    var dinoLayer: some View {
        let currentImageName = getDinoImageName()
        let layout = getDinoLayout(for: step, imageName: currentImageName)
        
        return VStack {
            Spacer()
            Image(currentImageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: layout.dinoWidth)
                .offset(x: layout.dinoOffset.x, y: layout.dinoOffset.y)
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: step)
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: dinoOffsetY)
                .id(currentImageName)
        }
        .padding(.bottom, step == 0 ? -10 : -30)
    }
    
    var uiOverlayLayer: some View {
        let currentImageName = getDinoImageName()
        let layout = getDinoLayout(for: step, imageName: currentImageName)
        
        return VStack {
            Spacer()
            ZStack {
                if !dinoText.isEmpty {
                    SpeechBubble(text: dinoText)
                        .frame(width: 280)
                        .scaleEffect(textSizeMultiplier)
                        .offset(x: layout.bubbleOffset.x, y: layout.bubbleOffset.y)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: step)
                }
                
                if showStartButton && step == 0 {
                    Button(action: {
                        showStartButton = false
                        startExerciseScenario()
                    }) {
                        Text("Start")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color(hex: "6155F5"))
                            .cornerRadius(14)
                    }
                    .offset(x: 120, y: -300)
                    .transition(.opacity)
                }
            }
        }
        .padding(.bottom, step == 0 ? 0 : -30)
    }
    
    var skipButtonLayer: some View {
        HStack {
            Spacer()
            Button(action: finishInstruction) {
                Text("Skip")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(step == 0 ? Color(hex: "6155F5") : .white)
                    .shadow(color: step == 0 ? .clear : .black.opacity(0.8), radius: 2, x: 0, y: 1)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 40)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    // MARK: - Logic & Scenarios
    
    private func setupInstruction() {
        arManager.start()
        startScenario()
    }
    
    private func toggleSound() {
        isSoundOn.toggle()
        if isSoundOn && !dinoText.isEmpty {
            SpeechManager.shared.speak(text: dinoText)
        } else {
            SpeechManager.shared.stop()
        }
    }
    
    struct DinoLayout {
        let dinoWidth: CGFloat
        let dinoOffset: CGPoint
        let bubbleOffset: CGPoint
    }
    
    func getDinoLayout(for step: Int, imageName: String) -> DinoLayout {
        var width: CGFloat = 240
        var dinoX: CGFloat = 0
        var dinoY: CGFloat = 0
        var bubbleX: CGFloat = 0
        var bubbleY: CGFloat = 0
        
        let isEyeSprite = imageName.contains("look_") || imageName == "dino_paws"
        
        switch step {
        case 0:
            width = 240; dinoY = -10; bubbleX = 0; bubbleY = -420
        case 2, 3:
            width = 440; dinoY = 170; bubbleX = -20; bubbleY = -595
        case 1, 4, 5:
            width = 300; dinoY = -20 + dinoOffsetY; bubbleX = 0; bubbleY = -470
        default:
            width = 239.22
        }
        
        return DinoLayout(dinoWidth: width, dinoOffset: CGPoint(x: dinoX, y: dinoY), bubbleOffset: CGPoint(x: bubbleX, y: bubbleY))
    }

    func getDinoImageName() -> String {
        if exerciseName == "Blinking" || exerciseName == "Blink and Focus" {
            return isDinoBlinking ? "dino_blink" : "dino"
        }
        else if exerciseName == "Horizon" && isAnimationRunning { return isDinoBlinking ? "look_right" : "look_left" }
        else if exerciseName == "Vertical" && isAnimationRunning { return isDinoBlinking ? "look_up" : "look_down" }
        else if (exerciseName == "Figure 8" || exerciseName == "Circle" || exerciseName == "Massage") && isAnimationRunning {
            return demoDirection
        }
        return "dino"
    }
    
    func finishInstruction() {
        UserDefaults.standard.set(true, forKey: "hasSeen_\(exerciseName)")
        onFinishInstruction()
    }
    
    func startScenario(forceIntro: Bool = false) {
        isAnimationRunning = false
        demoDirection = "dino"
        
        if skipIntro && !forceIntro {
            showStartButton = false
            startExerciseScenario()
        } else if !isFirstInSession && !forceIntro {
            showStartButton = false
            startExerciseScenario()
        } else {
            step = 0
            dinoText = "Hi! I am Dino and I will help you to complete these exercises right!"
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { withAnimation { showStartButton = true } }
        }
    }
    
    func startExerciseScenario() {
        switch exerciseName {
        case "Zig Zag": runZigZagScenario()
        case "Spiral": runSpiralScenario()
        case "Blinking": runBlinkingScenario()
        case "Horizon": runHorizonScenario()
        case "Vertical": runVerticalScenario()
        case "Figure 8": runFigure8Scenario()
        case "Circle": runCircleScenario()
        case "Massage": runMassageScenario()
        case "Focus": runFocusScenario()
        case "Blink and Focus": runBlinkAndFocusScenario()
        case "Unfocus": runUnfocusScenario()
        default: finishInstruction()
        }
    }
    
    // MARK: - Exercise Scenarios
    
    func runZigZagScenario() {
        step = 1; dinoOffsetY = 50; dinoText = "Put your phone in front of you."
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.step = 4; self.dinoText = "Follow the capsule only with your eyes!"
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.visualDemoProgress = 0.0
                withAnimation(.easeInOut(duration: 8.0)) { self.visualDemoProgress = 1.0 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 8.5) { self.finishInstruction() }
            }
        }
    }
    
    func runSpiralScenario() {
        step = 1; dinoOffsetY = 50; dinoText = "Put your phone in front of you."
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.step = 4; self.dinoText = "Follow the capsule only with your eyes!"
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.visualDemoProgress = 0.0
                withAnimation(.easeInOut(duration: 8.0)) { self.visualDemoProgress = 1.0 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 8.5) { self.finishInstruction() }
            }
        }
    }

    func runFocusScenario() {
        step = 1; dinoText = "Put your head in the frame."
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.step = 2; self.dinoText = "Look! A dot will appear in the center."; self.dinoOffsetY = 15
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.step = 3; self.dinoText = "Focus your vision right on it. Don't look away!"
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                    self.step = 4; self.dinoOffsetY = 50; self.dinoText = "Keep your eyes wide open. Do not blink for 15 seconds."
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
                        self.dinoText = "Ready? Let's start!"
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { self.finishInstruction() }
                    }
                }
            }
        }
    }

    func runBlinkingScenario() {
        step = 1; dinoText = "Make sure your face positioned right in the circle."
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            self.step = 2; self.dinoText = "Just like this!"; self.dinoOffsetY = 15;
            self.isDinoBlinking = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { self.isDinoBlinking = false }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.step = 3; self.dinoText = "On the count 3 start blinking like this:"
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                    self.step = 4; self.dinoOffsetY = 50; self.dinoText = "Let's try together before starting!"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        self.dinoText = "Put your head in the frame."
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            self.step = 5; self.dinoText = "On the count 3 blink with me!"
                            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                                self.dinoText = "Blink!"; self.isDinoBlinking = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    self.isDinoBlinking = false
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                        self.dinoText = "Perfect! Now do on your own!"
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { self.finishInstruction() }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    func runHorizonScenario() {
        step = 1; dinoText = "Keep your head still. Use only your eyes!"
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            self.step = 2; self.dinoText = "Just like this!"; self.dinoOffsetY = 15
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.step = 3; self.dinoText = "On the count 3 look right then left:"
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                    self.isAnimationRunning = true; self.isDinoBlinking = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        self.isAnimationRunning = false; self.step = 4; self.dinoOffsetY = 50; self.dinoText = "Let's try together before starting!"
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            self.dinoText = "Keep your head still."
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                self.step = 5; self.dinoText = "On the count 3 look Right then Left!"
                                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                                    self.isAnimationRunning = true; self.dinoText = "Right!"; self.isDinoBlinking = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                        self.dinoText = "Left!"; self.isDinoBlinking = false
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                            self.isAnimationRunning = false; self.dinoText = "Perfect! Now do on your own!"
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { self.finishInstruction() }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    func runVerticalScenario() {
        step = 1; dinoText = "Keep your head still. Use only your eyes!"
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            self.step = 2; self.dinoText = "Just like this!"; self.dinoOffsetY = 15
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.step = 3; self.dinoText = "On the count 3 look Up then Down:"
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                    self.isAnimationRunning = true; self.isDinoBlinking = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        self.isAnimationRunning = false; self.step = 4; self.dinoOffsetY = 50; self.dinoText = "Let's try together before starting!"
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            self.dinoText = "Keep your head still."
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                self.step = 5; self.dinoText = "On the count 3 look Up then Down!"
                                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                                    self.isAnimationRunning = true; self.dinoText = "Up!"; self.isDinoBlinking = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                        self.dinoText = "Down!"; self.isDinoBlinking = false
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                            self.isAnimationRunning = false; self.dinoText = "Perfect! Now do on your own!"
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { self.finishInstruction() }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    func runFigure8Scenario() {
        step = 1; dinoText = "Keep your head still. Follow the pattern!"
        isAnimationRunning = false; demoDirection = "dino"
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            self.step = 2; self.dinoText = "Just like this!"; self.dinoOffsetY = 15
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.step = 3; self.dinoText = "Make a figure 8 with your eyes:"
                DispatchQueue.main.asyncAfter(deadline: .now() + 7.5) {
                    self.isAnimationRunning = false; self.step = 4; self.dinoOffsetY = 50; self.dinoText = "Let's try together!"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        self.dinoText = "Keep your head still."
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            self.step = 5; self.dinoText = "On the count 3 start!"
                            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                                self.isAnimationRunning = true; self.dinoText = "Go!"; self.demoDirection = "look_up"
                                DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
                                    self.dinoText = "Excellent!"; self.isAnimationRunning = false
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                        self.dinoText = "Perfect! Now do on your own!"
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { self.finishInstruction() }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    func runCircleScenario() {
        step = 1; dinoText = "Keep your head still. Follow the pattern!"
        isAnimationRunning = false; demoDirection = "dino"
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            self.step = 2; self.dinoText = "Just like this!"; self.dinoOffsetY = 15
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.step = 3; self.dinoText = "Make a circle with your eyes:"
                DispatchQueue.main.asyncAfter(deadline: .now() + 6.5) {
                    self.isAnimationRunning = false; self.step = 4; self.dinoOffsetY = 50; self.dinoText = "Let's try together!"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        self.dinoText = "Keep your head still."
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            self.step = 5; self.dinoText = "On the count 3 start!"
                            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                                self.isAnimationRunning = true; self.dinoText = "Go!"; self.demoDirection = "look_up"
                                DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
                                    self.dinoText = "Excellent!"; self.isAnimationRunning = false
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                        self.dinoText = "Perfect! Now do on your own!"
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { self.finishInstruction() }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    func runMassageScenario() {
        step = 1; dinoText = "Put your head in the frame."
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            self.step = 2; self.dinoText = "Just like this!"; self.dinoOffsetY = 15
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                self.step = 3; self.dinoText = "You have to close your eyes and massage them for 30 seconds like this:"
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
                    self.isAnimationRunning = true; self.demoDirection = "dino_blink"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.demoDirection = "dino_paws"; self.dinoText = "Keep doing this until you hear a short bz-bz sound."
                        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
                            self.isAnimationRunning = false; self.demoDirection = "dino"
                            self.step = 4; self.dinoOffsetY = 50; self.dinoText = "Perfect! Now do on your own!"
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { self.finishInstruction() }
                        }
                    }
                }
            }
        }
    }

    func runBlinkAndFocusScenario() {
        step = 1; dinoText = "This is a complex one! Listen carefully."
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            self.step = 2; self.dinoText = "First, blink as fast as you can for 10 seconds!"; self.dinoOffsetY = 15
            self.isAnimationRunning = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
                self.isDinoBlinking = false; self.isAnimationRunning = false
                self.step = 3; self.dinoText = "Then, stare at the center dot without blinking for 5 seconds."
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    self.step = 4; self.dinoOffsetY = 50; self.dinoText = "We will repeat this 3 times."
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                        self.dinoText = "Ready? Set? Go!"
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { self.finishInstruction() }
                    }
                }
            }
        }
    }

    func runUnfocusScenario() {
        step = 1; dinoText = "Let's relax. Put your head in the frame."
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            self.step = 2; self.dinoText = "Look at the deep purple color on the screen."; self.dinoOffsetY = 15
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                self.step = 3; self.dinoText = "Try to look THROUGH the screen, into the depth."
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
                    self.step = 4; self.dinoOffsetY = 50; self.dinoText = "Unfocus your vision completely. Try not to blink."
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
                        self.dinoText = "Relax your eyes. Let's start."
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { self.finishInstruction() }
                    }
                }
            }
        }
    }
}

// ====================================================================
// 🔥 ФОН З АДАПТАЦІЄЮ ПІД ДАРК МОД 🔥
// ====================================================================
struct AnimatedIntroBackground: View {
    @State private var isAnimating = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let isDark = colorScheme == .dark
        ZStack {
            (isDark ? Color.black : Color(hex: "F4F2FF")).ignoresSafeArea()
            
            Circle()
                .fill(Color(hex: "6155F5").opacity(isDark ? 0.3 : 0.12))
                .frame(width: 350, height: 350)
                .blur(radius: 90)
                .offset(x: isAnimating ? -80 : 50, y: isAnimating ? -150 : -50)
            
            Circle()
                .fill(Color(hex: "8A81FF").opacity(isDark ? 0.35 : 0.18))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: isAnimating ? 120 : 20, y: isAnimating ? 200 : 100)
            
            Circle()
                .fill(Color(hex: "DCD9FF").opacity(isDark ? 0.15 : 0.25))
                .frame(width: 400, height: 400)
                .blur(radius: 120)
                .offset(x: isAnimating ? 20 : -100, y: isAnimating ? 50 : 250)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

import SwiftUI

struct InstructionView: View {
    var exerciseName: String
    var exerciseQueue: [String] = []
    
    var skipIntro: Bool = false
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var userManager: UserManager
    
    @AppStorage("voiceGuidance") var isSoundOn: Bool = true
    @AppStorage("textSizeMultiplier") var textSizeMultiplier: Double = 1.0
    
    @State private var hasSeenInstruction = false
    @State private var startGame = false
    
    // Етапи сценарію
    @State private var step: Int = 0
    @State private var dinoText: String = ""
    @State private var showStartButton = false
    @State private var isDinoBlinking = false
    @State private var dinoOffsetY: CGFloat = 50
    
    @State private var isAnimationRunning = false
    @State private var demoDirection: String = "dino"
    
    @StateObject private var arManager = ARManager()
    
    var body: some View {
        Group {
            if startGame || hasSeenInstruction {
                ExerciseView(
                    exerciseName: exerciseName,
                    exerciseQueue: exerciseQueue,
                    onReplayInstruction: {
                        self.resetInstructionState()
                    }
                )
                .navigationBarHidden(true)
            } else {
                content
            }
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
    
    var content: some View {
        ZStack {
            // 1. ФОН
            if step == 0 {
                AnimatedIntroBackground().transition(.opacity)
            } else {
                ARCameraView(arManager: arManager).ignoresSafeArea()
            }
            
            // 2. ДІНОЗАВР (ЗА РАМКОЮ)
            dinoLayer
            
            // 3. РАМКА ДЛЯ ОБЛИЧЧЯ (AR)
            if step > 0 {
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
            
            // 4. БУЛЬБАШКА ТА КНОПКА START (ПОВЕРХ РАМКИ)
            uiOverlayLayer
            
            // 5. ВЕРХНЯ ПАНЕЛЬ І КНОПКА SKIP
            topBar
            skipButtonLayer
        }
    }
    
    // MARK: - Views Breakdown
    
    var topBar: some View {
        VStack {
            ZStack {
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
                .multilineTextAlignment(.center)
                .padding(.horizontal, 60)

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
            .padding(.top, 10)
            Spacer()
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
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: finishInstruction) {
                    Text("Skip")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(step == 0 ? Color(hex: "6155F5") : .white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.4), lineWidth: 1)
                        )
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                }
                .padding(.trailing, 30)
                .padding(.bottom, 40)
                .offset(x: 0)
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    // MARK: - Logic & Configuration
    
    private func setupInstruction() {
        hasSeenInstruction = UserDefaults.standard.bool(forKey: "hasSeen_\(exerciseName)")
        if !hasSeenInstruction {
            arManager.start()
            startScenario()
        }
    }
    
    private func resetInstructionState() {
        self.hasSeenInstruction = false
        self.startGame = false
        self.step = 0
        self.dinoOffsetY = 50
        self.isAnimationRunning = false
        self.demoDirection = "dino"
        self.arManager.start()
        self.startScenario(forceIntro: true)
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
            width = 240
            dinoY = -10
            bubbleX = 0
            bubbleY = -420
            
        case 2, 3:
            width = isEyeSprite ? 440 : 440
            dinoY = 170
            bubbleX = -20
            bubbleY = -595
            
        case 1, 4, 5:
            width = isEyeSprite ? 300 : 300
            dinoY = -20 + dinoOffsetY
            bubbleX = 0
            bubbleY = -470
            
        default:
            width = 239.22
        }
        
        var spriteOffsetX: CGFloat = 0
        var spriteOffsetY: CGFloat = 0
        
        switch imageName {
        case "look_right": spriteOffsetX = 0
        case "look_left": spriteOffsetX = 0
        default: break
        }
        
        if step == 4 || step == 5 {
            spriteOffsetX = spriteOffsetX * 0.6
        }
        
        dinoX += spriteOffsetX
        dinoY += spriteOffsetY
        
        return DinoLayout(
            dinoWidth: width,
            dinoOffset: CGPoint(x: dinoX, y: dinoY),
            bubbleOffset: CGPoint(x: bubbleX, y: bubbleY)
        )
    }

    func getDinoImageName() -> String {
        let isDemo = (step == 2 || step == 3)
        
        if exerciseName == "Blinking" {
            return isDinoBlinking ? "dino_blink" : "dino"
        }
        else if exerciseName == "Horizon" {
            if isAnimationRunning { return isDinoBlinking ? "look_right" : "look_left" }
        }
        else if exerciseName == "Vertical" {
            if isAnimationRunning { return isDinoBlinking ? "look_up" : "look_down" }
        }
        else if exerciseName == "Figure 8" || exerciseName == "Circle" || exerciseName == "Massage" {
            if isAnimationRunning { return demoDirection }
        }
        return "dino"
    }
    
    func finishInstruction() {
        UserDefaults.standard.set(true, forKey: "hasSeen_\(exerciseName)")
        startGame = true
    }
    
    func startScenario(forceIntro: Bool = false) {
        isAnimationRunning = false
        demoDirection = "dino"
        
        if skipIntro && !forceIntro {
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
        case "Blinking": runBlinkingScenario()
        case "Horizon": runHorizonScenario()
        case "Vertical": runVerticalScenario()
        case "Figure 8": runFigure8Scenario()
        case "Circle": runCircleScenario()
        case "Massage": runMassageScenario() // 🔥 ОНОВЛЕНО
        default: finishInstruction()
        }
    }
    
    // ==========================================
    // 🔥 ОНОВЛЕНИЙ СЦЕНАРІЙ ДЛЯ МАСАЖУ 🔥
    // ==========================================
    func runMassageScenario() {
        step = 1; dinoText = "Put your head in the frame."
        isAnimationRunning = false
        demoDirection = "dino"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            self.step = 2; self.dinoText = "Just like this!"; self.dinoOffsetY = 15
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                self.step = 3; self.dinoText = "You have to close your eyes and massage them for 30 seconds like this:"
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
                    // Діно просто закриває очі
                    self.isAnimationRunning = true
                    self.demoDirection = "dino_blink"
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        // Після затримки кладе лапки на очі
                        self.demoDirection = "dino_paws"
                        self.dinoText = "Keep doing this until you hear a short bz-bz sound."
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
                            // Завершення
                            self.isAnimationRunning = false
                            self.demoDirection = "dino"
                            self.step = 4; self.dinoOffsetY = 50; self.dinoText = "Perfect! Now do on your own!"
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                self.finishInstruction()
                            }
                        }
                    }
                }
            }
        }
    }
    
    // --- ІНШІ СЦЕНАРІЇ ---
    
    func runBlinkingScenario() {
        step = 1; dinoText = "Make sure your face positioned right in the circle."
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            self.step = 2; self.dinoText = "Just like this!"; self.dinoOffsetY = 15;
            
            self.isDinoBlinking = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { self.isDinoBlinking = false }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { self.isDinoBlinking = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { self.isDinoBlinking = false }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.step = 3; self.dinoText = "On the count 3 start blinking like this:"
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { self.isDinoBlinking = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) { self.isDinoBlinking = false }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { self.isDinoBlinking = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.3) { self.isDinoBlinking = false }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                    self.step = 4; self.dinoOffsetY = 50; self.dinoText = "Let's try together before starting!"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        self.dinoText = "Put your head in the frame."
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            self.step = 5; self.dinoText = "On the count 3 blink with me!"
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { self.dinoText = " 1... " }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { self.dinoText = " 2... " }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { self.dinoText = " 3... " }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                                
                                self.dinoText = "Blink!"
                                self.isDinoBlinking = true
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
        isAnimationRunning = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            self.step = 2; self.dinoText = "Just like this!"; self.dinoOffsetY = 15
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.step = 3; self.dinoText = "On the count 3 look right then left:"
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                    self.isAnimationRunning = true
                    self.isDinoBlinking = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.isDinoBlinking = false }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { self.isDinoBlinking = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { self.isDinoBlinking = false }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        self.isAnimationRunning = false
                        self.step = 4; self.dinoOffsetY = 50; self.dinoText = "Let's try together before starting!"
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            self.dinoText = "Keep your head still."
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                self.step = 5; self.dinoText = "On the count 3 look Right then Left!"
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { self.dinoText = " 1... " }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { self.dinoText = " 2... " }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { self.dinoText = " 3... " }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                                    self.isAnimationRunning = true
                                    self.dinoText = "Right!"; self.isDinoBlinking = true
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
        isAnimationRunning = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            self.step = 2; self.dinoText = "Just like this!"; self.dinoOffsetY = 15
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.step = 3; self.dinoText = "On the count 3 look Up then Down:"
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                    self.isAnimationRunning = true
                    self.isDinoBlinking = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.isDinoBlinking = false }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { self.isDinoBlinking = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { self.isDinoBlinking = false }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        self.isAnimationRunning = false
                        self.step = 4; self.dinoOffsetY = 50; self.dinoText = "Let's try together before starting!"
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            self.dinoText = "Keep your head still."
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                self.step = 5; self.dinoText = "On the count 3 look Up then Down!"
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { self.dinoText = " 1... " }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { self.dinoText = " 2... " }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { self.dinoText = " 3... " }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                                    self.isAnimationRunning = true
                                    self.dinoText = "Up!"; self.isDinoBlinking = true
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
        isAnimationRunning = false
        demoDirection = "dino"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            self.step = 2; self.dinoText = "Just like this!"; self.dinoOffsetY = 15
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.step = 3; self.dinoText = "Make a figure 8 with your eyes:"
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    self.isAnimationRunning = true
                    
                    self.demoDirection = "look_up"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { self.demoDirection = "look_right" }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { self.demoDirection = "dino" }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { self.demoDirection = "look_up" }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { self.demoDirection = "look_left" }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { self.demoDirection = "look_down" }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) { self.demoDirection = "dino" }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 7.5) {
                        self.isAnimationRunning = false
                        self.step = 4; self.dinoOffsetY = 50; self.dinoText = "Let's try together!"
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            self.dinoText = "Keep your head still."
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                self.step = 5; self.dinoText = "On the count 3 start!"
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { self.dinoText = " 1... " }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { self.dinoText = " 2... " }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { self.dinoText = " 3... " }
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                                    self.isAnimationRunning = true
                                    self.dinoText = "Go!"; self.demoDirection = "look_up"
                                    
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { self.demoDirection = "look_right" }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { self.demoDirection = "dino" }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { self.demoDirection = "look_up" }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { self.demoDirection = "look_left" }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { self.demoDirection = "look_down" }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) { self.demoDirection = "dino" }
                                    
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 7.0) {
                                        self.dinoText = "Excellent!"
                                        self.isAnimationRunning = false
                                        
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                            self.dinoText = "Perfect! Now do on your own!"
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                                self.finishInstruction()
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
    }

    func runCircleScenario() {
        step = 1; dinoText = "Keep your head still. Follow the pattern!"
        isAnimationRunning = false
        demoDirection = "dino"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            self.step = 2; self.dinoText = "Just like this!"; self.dinoOffsetY = 15
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.step = 3; self.dinoText = "Make a circle with your eyes:"
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    self.isAnimationRunning = true
                    
                    self.demoDirection = "look_up"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { self.demoDirection = "look_right" }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { self.demoDirection = "look_down" }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { self.demoDirection = "look_left" }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { self.demoDirection = "look_up" }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { self.demoDirection = "dino" }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 6.5) {
                        self.isAnimationRunning = false
                        self.step = 4; self.dinoOffsetY = 50; self.dinoText = "Let's try together!"
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            self.dinoText = "Keep your head still."
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                self.step = 5; self.dinoText = "On the count 3 start!"
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { self.dinoText = " 1... " }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { self.dinoText = " 2... " }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { self.dinoText = " 3... " }
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                                    self.isAnimationRunning = true
                                    self.dinoText = "Go!"; self.demoDirection = "look_up"
                                    
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { self.demoDirection = "look_right" }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { self.demoDirection = "look_down" }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { self.demoDirection = "look_left" }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { self.demoDirection = "look_up" }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { self.demoDirection = "dino" }
                                    
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
                                        self.dinoText = "Excellent!"
                                        self.isAnimationRunning = false
                                        
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                            self.dinoText = "Perfect! Now do on your own!"
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                                self.finishInstruction()
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
    }
}

// ФОН З М'ЯКИМИ РОЗМИТИМИ КРУЖЕЧКАМИ
struct AnimatedIntroBackground: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Color(hex: "F4F2FF")
                .ignoresSafeArea()
            
            Circle()
                .fill(Color(hex: "6155F5").opacity(0.12))
                .frame(width: 350, height: 350)
                .blur(radius: 90)
                .offset(x: isAnimating ? -80 : 50, y: isAnimating ? -150 : -50)
            
            Circle()
                .fill(Color(hex: "8A81FF").opacity(0.18))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: isAnimating ? 120 : 20, y: isAnimating ? 200 : 100)
            
            Circle()
                .fill(Color(hex: "DCD9FF").opacity(0.25))
                .frame(width: 400, height: 400)
                .blur(radius: 120)
                .offset(x: isAnimating ? 20 : -100, y: isAnimating ? 50 : 250)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    InstructionView(exerciseName: "Massage", exerciseQueue: ["Massage", "Circle"])
        .environmentObject(UserManager())
}

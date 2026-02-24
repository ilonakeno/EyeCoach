import SwiftUI

// 1. Створюємо перелік доступних фігур
enum SpotlightShapeType {
    case rectangle(cornerRadius: CGFloat)
    case circle
    case ellipse
    case capsule
}

// 2. Створюємо структуру для зберігання координат (Єдине джерело правди)
struct SpotlightData {
    var type: SpotlightShapeType
    var width: CGFloat
    var height: CGFloat
    var offsetX: CGFloat = 0
    var offsetY: CGFloat = 0
}

struct InteractiveOnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @EnvironmentObject var userManager: UserManager
    
    @State private var step: Int = 0
    @State private var isPulsing: Bool = false
    @State private var animateBlobs: Bool = false
    
    let brandColor = Color(red: 0.38, green: 0.33, blue: 0.96)
    
    var body: some View {
        let screenWidth = UIScreen.main.bounds.width
        
        ZStack {
            // 1. ФОНОВИЙ ІНТЕРФЕЙС
            Group {
                switch step {
                case 0, 1, 2, 3, 7, 10, 14: MockHomeUI()
                case 4, 5, 6: MockProfileUI()
                case 8: MockMyExercisesDetailUI()
                case 9: MockAllExercisesDetailUI()
                // 🔥 ДОДАНО КРОК 13 ДЛЯ НОВОГО ЕКРАНУ 🔥
                case 11, 12, 13: MockExerciseUI()
                default: MockHomeUI()
                }
            }
            .blur(radius: step <= 1 ? 12 : 0)
            .animation(.easeInOut(duration: 0.5), value: step)
            
            // 2. ТЕМНИЙ ОВЕРЛЕЙ З "ДІРКАМИ" (МАСКА)
            Color.black.opacity(step <= 1 ? 0.4 : 0.65)
                .reverseMask {
                    // 🔥 ЗБІЛЬШЕНО ДІАПАЗОН ДО 14 🔥
                    if step > 1 && step < 14, let data = getSpotlightData(for: step, w: screenWidth) {
                        renderSpotlight(data: data, isGlow: false)
                            .transition(.opacity)
                            .id("mask_\(step)")
                    }
                }
                .ignoresSafeArea()
            
            // 3. ✨ М'ЯКЕ СВІТІННЯ (ПІДСВІТКА) ✨
            // 🔥 ЗБІЛЬШЕНО ДІАПАЗОН ДО 14 🔥
            if step > 1 && step < 14, let data = getSpotlightData(for: step, w: screenWidth) {
                renderSpotlight(data: data, isGlow: true)
                    .transition(.opacity)
                    .id("glow_\(step)")
            }
            
            // 4. ✨ МАГІЧНИЙ ЕКРАН "HELLO"
            if step == 0 {
                ZStack {
                    Circle().fill(brandColor.opacity(0.6)).frame(width: 300).blur(radius: 60)
                        .offset(x: animateBlobs ? 80 : -100, y: animateBlobs ? -150 : 100).scaleEffect(animateBlobs ? 1.4 : 0.8)
                    Circle().fill(Color(red: 0.7, green: 0.5, blue: 1.0).opacity(0.5)).frame(width: 250).blur(radius: 80)
                        .offset(x: animateBlobs ? -120 : 120, y: animateBlobs ? 100 : -120).scaleEffect(animateBlobs ? 0.9 : 1.5)
                    Circle().fill(Color(red: 0.7, green: 0.5, blue: 1.0).opacity(0.5)).frame(width: 200).blur(radius: 50)
                        .offset(x: animateBlobs ? 50 : -30, y: animateBlobs ? 50 : -50).scaleEffect(animateBlobs ? 1.6 : 1.0)
                    
                    Text("Hello").font(.system(size: 64, weight: .bold, design: .rounded)).foregroundColor(.white)
                        .shadow(color: brandColor.opacity(0.5), radius: 20).scaleEffect(isPulsing ? 1.03 : 0.97)
                }.transition(.opacity)
            }
            
            // 5. 🔥 ДИНАМІЧНИЙ ДІНО ТА БУЛЬБАШКА 🔥
            if step >= 1 {
                ZStack {
                    let placement = getPlacement(for: step)
                    
                    Image("dino")
                        .resizable()
                        .scaledToFit()
                        .frame(width: dinoWidth(for: step))
                        .offset(x: placement.dino.x, y: placement.dino.y)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: step)
                    
                    SpeechBubble(text: dinoMessage(for: step))
                        // 🔥 ТЕПЕР ШИРИНА БУЛЬБАШКИ ЗАВЖДИ ОДНАКОВА 🔥
                        .frame(width: 280)
                        .offset(x: placement.bubble.x, y: placement.bubble.y)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: step)
                }
            }
            
            // 6. НЕВИДИМА КНОПКА ПЕРЕХОДУ
            Color.white.opacity(0.001).ignoresSafeArea().onTapGesture {
                // 🔥 ОНОВЛЕНО МАКСИМАЛЬНИЙ КРОК 🔥
                withAnimation(.easeInOut(duration: 0.5)) { if step < 14 { step += 1 } else { hasSeenOnboarding = true } }
            }
            
            // 7. КНОПКА SKIP ТА ТЕКСТ-ПІДКАЗКА
            VStack {
                // 🔥 ОНОВЛЕНО МАКСИМАЛЬНИЙ КРОК 🔥
                HStack { Spacer(); if step < 14 { Button(action: { withAnimation { hasSeenOnboarding = true } }) { Text("Skip Tour").font(.subhead).bold().foregroundColor(.white).padding(.horizontal, 16).padding(.vertical, 8).background(Color.white.opacity(0.2)).clipShape(Capsule()) } } }.padding(.horizontal, 20).padding(.top, 20).offset(x: -260)
                Spacer()
                // 🔥 ОНОВЛЕНО УМОВУ ДЛЯ ФІНАЛЬНОГО КРОКУ 🔥
                Text(step == 14 ? "Tap anywhere to start!" : "Tap anywhere on the screen to continue")
                    .font(.subhead).foregroundColor(.white.opacity(0.7)).opacity(isPulsing ? 1.0 : 0.4).padding(.bottom, 30).allowsHitTesting(false)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) { isPulsing = true }
            withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) { animateBlobs = true }
        }
    }
    
    // =========================================================================
    // 🔥 РОЗУМНЕ ПОЗИЦІОНУВАННЯ ДІНО (Single Source of Truth для поз) 🔥
    // =========================================================================
    func getPlacement(for step: Int) -> (dino: CGPoint, bubble: CGPoint) {
        switch step {
        // 🔥 ОНОВЛЕНО ФІНАЛЬНИЙ КРОК 🔥
        case 1, 14:
            return (CGPoint(x: 0, y: 130), CGPoint(x: 0, y: -140))
            
        case 2: return (CGPoint(x: -110, y: 200), CGPoint(x: -10, y: -5))
        case 3: return (CGPoint(x: -110, y: 200), CGPoint(x: -10, y: -5))
        case 4: return (CGPoint(x: -120, y: 300), CGPoint(x: -20, y: 90))
        case 5: return (CGPoint(x: -30, y: -100), CGPoint(x: 50, y: -280))
        case 6: return (CGPoint(x: -110, y: 50), CGPoint(x: -5, y: -165))
        case 7: return (CGPoint(x: -110, y: 280), CGPoint(x: -38, y: 70))
        case 8: return (CGPoint(x: -110, y: 280), CGPoint(x: -20, y: 58))
        case 9: return (CGPoint(x: -120, y: 400), CGPoint(x: -20, y: 200))
        case 10: return (CGPoint(x: -110, y: -10), CGPoint(x: 0, y: -220))
        case 11: return (CGPoint(x: -120, y: 300), CGPoint(x: -20, y: 90))
        case 12: return (CGPoint(x: -120, y: 300), CGPoint(x: -20, y: 90))
            
        // 🔥 ДОДАНО: Крок 13 (Кнопка звуку) - Діно внизу, бульбашка над ним 🔥
        case 13: return (CGPoint(x: -120, y: 300), CGPoint(x: -20, y: 90))
            
        default: return (CGPoint(x: -80, y: 200), CGPoint(x: 30, y: 80))
        }
    }
    //=========================================================================
    
    // 🔥 ЄДИНЕ ДЖЕРЕЛО ПРАВДИ ДЛЯ КООРДИНАТ 🔥
    func getSpotlightData(for step: Int, w: CGFloat) -> SpotlightData? {
        switch step {
        case 2: return SpotlightData(type: .rectangle(cornerRadius: 24), width: w - 40, height: 145, offsetY: -185)
        case 3: return SpotlightData(type: .circle, width: 52, height: 50, offsetX: w/2 - 45, offsetY: -295)
        case 4: return SpotlightData(type: .rectangle(cornerRadius: 24), width: w - 40, height: 250, offsetY: -150)
        case 5: return SpotlightData(type: .rectangle(cornerRadius: 24), width: w - 30, height: 170, offsetY: 60)
        case 6: return SpotlightData(type: .rectangle(cornerRadius: 24), width: w - 30, height: 170, offsetY: 280)
        case 7: return SpotlightData(type: .circle, width: 50, height: 50, offsetX: w/2 - 58, offsetY: -6)
        case 8: return SpotlightData(type: .rectangle(cornerRadius: 24), width: w - 40, height: 180, offsetY: -140)
        case 9: return SpotlightData(type: .rectangle(cornerRadius: 24), width: w - 40, height: 450, offsetY: 0)
        case 10: return SpotlightData(type: .rectangle(cornerRadius: 24), width: w - 30, height: 100, offsetY: 178)
        case 11: return SpotlightData(type: .ellipse, width: 280, height: 400, offsetY: 20)
        case 12: return SpotlightData(type: .capsule, width: 120, height: 52, offsetX: w/2 - 75, offsetY: -305)
            
        // 🔥 ДОДАНО: Крок 13 (Кнопка звуку) - Круглий спотлайт навколо іконки динаміка 🔥
        case 13: return SpotlightData(type: .circle, width: 54, height: 54, offsetX: w/2 - 45, offsetY: -237)
            
        default: return nil
        }
    }
    
    // --- УНІВЕРСАЛЬНИЙ РЕНДЕР ---
    @ViewBuilder
    func renderSpotlight(data: SpotlightData, isGlow: Bool) -> some View {
        let lw: CGFloat = 16
        let bl: CGFloat = isPulsing ? 18 : 8
        let op: Double = isPulsing ? 0.9 : 0.4
        
        Group {
            switch data.type {
            case .rectangle(let radius):
                if isGlow { RoundedRectangle(cornerRadius: radius).stroke(brandColor, lineWidth: lw).blur(radius: bl).opacity(op) }
                else { RoundedRectangle(cornerRadius: radius) }
            case .circle:
                if isGlow { Circle().stroke(brandColor, lineWidth: lw).blur(radius: bl).opacity(op) }
                else { Circle() }
            case .ellipse:
                if isGlow { Ellipse().stroke(brandColor, lineWidth: lw).blur(radius: bl).opacity(op) }
                else { Ellipse() }
            case .capsule:
                if isGlow { Capsule().stroke(brandColor, lineWidth: lw).blur(radius: bl).opacity(op) }
                else { Capsule() }
            }
        }
        .frame(width: data.width, height: data.height)
        .offset(x: data.offsetX, y: data.offsetY)
    }
    
    // --- РОЗМІР ДІНО ---
    func dinoWidth(for step: Int) -> CGFloat {
        switch step {
        case 1, 14: return 250 // 🔥 ОНОВЛЕНО ФІНАЛЬНИЙ КРОК 🔥
        case 5: return 130
        default: return 170
        }
    }

    // --- РОЗУМНЕ ПОЗИЦІОНУВАННЯ ДІНО ---
    func dinoYOffset(for step: Int) -> CGFloat {
        switch step {
        // 🔥 ОНОВЛЕНО КРОКИ 🔥
        case 2, 3, 4, 8, 11, 12, 13: return 200
        case 5, 7: return 230
        case 6, 9, 10: return -200
        default: return 0
        }
    }
    
    // --- ТЕКСТИ ---
    func dinoMessage(for step: Int) -> String {
        switch step {
        case 1: return "Welcome to EyeGym! I'm Dino. Let me show you how to start training your vision."
        case 2: return "These numbers show your Daily Streak. Practice every day to build a healthy habit!"
        case 3: return "This is your Profile. Let's peek inside to see how you can customize your app!"
        case 4: return "Here you can log in to safely save your progress and access your data from anywhere."
        case 5: return "In Accessibility, turn on Voice Guidance so I can read the instructions out loud while you exercise."
        case 6: return "Tired eyes? Switch to Dark Mode here. You can also change the app language."
        case 7: return "Now, back to your routines! Tap this Play button to start the exercises from your list."
        case 8: return "Inside 'My exercises', you can customize your routine. Tap the red minus to remove an exercise."
        case 9: return "In 'All exercises', explore the full library. Tap the red plus to add new ones to your daily routine."
        case 10: return "Need a quick break? 'Eye-reliever' is a pre-made list of relaxing exercises. No setup needed!"
        case 11: return "During workouts, keep your face inside the frame. The camera tracks your eyes locally — 100% private!"
        case 12: return "Not sure how to do an exercise? Tap 'Tutorial' before starting for a quick guide."
        // 🔥 ДОДАНО ФРАЗУ ДЛЯ НОВОГО КРОКУ 🔥
        case 13: return "If you prefer silence, you can always quickly mute my voice guidance right here."
        // 🔥 ЗСУНУТО ФІНАЛЬНУ ФРАЗУ 🔥
        case 14: return "You're all set! Follow my lead and let's save your vision together."
        default: return ""
        }
    }
}

// ✨ МАГІЯ ВИРІЗАННЯ "ДІРОК" ✨
extension View {
    func reverseMask<Mask: View>(alignment: Alignment = .center, @ViewBuilder _ mask: () -> Mask) -> some View {
        self.mask(ZStack { Rectangle().fill(Color.white); mask().blendMode(.destinationOut) }.compositingGroup())
    }
}

// =========================================================
// ФЕЙКОВІ ІНТЕРФЕЙСИ (Моки)
// =========================================================
struct MockHomeUI: View {
    let brandColor = Color(red: 0.38, green: 0.33, blue: 0.96)
    var body: some View { VStack(spacing: 0) { HStack { Text("EyeGym").font(.largeTitle).fontWeight(.bold); Spacer(); Circle().fill(Color(.systemGray5)).frame(width: 50, height: 50).overlay(Image(systemName: "person.fill").foregroundColor(.gray)) }.padding(.horizontal, 20).padding(.top, 60); RoundedRectangle(cornerRadius: 24).fill(LinearGradient(colors: [Color.white, Color(red: 0.95, green: 0.94, blue: 1.0)], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(height: 130).overlay( HStack { Image("dino").resizable().scaledToFit().frame(width: 90).padding(.leading, 20); Spacer(); VStack { Text("--").font(.system(size: 36, weight: .bold)).foregroundColor(brandColor); Text("days streak").font(.headline).foregroundColor(brandColor.opacity(0.8)) }.padding(.trailing, 40) } ).padding(.horizontal, 20).padding(.top, 20); VStack(alignment: .leading, spacing: 15) { Text("Your lists").font(.title2).fontWeight(.bold).padding(.horizontal, 20).padding(.top, 30); MockListCard(title: "My exercises", subtitle: "View list", icon: "play.fill", iconBg: brandColor); MockListCard(title: "All exercises", subtitle: "View list", icon: "play.fill", iconBg: brandColor); MockListCard(title: "Eye-reliever", subtitle: "View list", icon: "play.fill", iconBg: brandColor); MockListCard(title: "Self sight testing", subtitle: "Coming soon", icon: "lock.fill", iconBg: .gray) }; Spacer() }.background(Color(.systemGroupedBackground).ignoresSafeArea()) }
}
struct MockProfileUI: View {
    let brandColor = Color(red: 0.38, green: 0.33, blue: 0.96)
    var body: some View { VStack(spacing: 20) { HStack { Circle().fill(Color.gray.opacity(0.2)).frame(width: 32, height: 32).overlay(Image(systemName: "xmark").font(.caption).bold().foregroundColor(.gray)); Spacer() }.padding(.horizontal, 20).padding(.top, 50); VStack(spacing: 12) { Text("Log in to save your progress &\nmedical data").font(.headline).multilineTextAlignment(.center).padding(.bottom, 10); RoundedRectangle(cornerRadius: 12).fill(.black).frame(height: 48).overlay(HStack { Image(systemName: "applelogo"); Text("Continue with Apple").bold() }.foregroundColor(.white)); RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.4), lineWidth: 1).frame(height: 48).overlay(HStack { Text("G").bold(); Text("Continue with Google").bold() }.foregroundColor(.primary)); RoundedRectangle(cornerRadius: 12).fill(brandColor).frame(height: 48).overlay(HStack { Image(systemName: "envelope.fill"); Text("Continue with Email").bold() }.foregroundColor(.white)) }.padding().background(Color.white).cornerRadius(24).padding(.horizontal, 20); VStack(alignment: .leading, spacing: 10) { Text("Accessibility").font(.subhead).bold().padding(.horizontal, 25); VStack(spacing: 15) { HStack { Text("Voice guidance"); Spacer(); Toggle("", isOn: .constant(true)).labelsHidden().tint(brandColor) }; Divider(); HStack { Text("Size"); Spacer(); Text("A").font(.caption); Slider(value: .constant(0.5)); Text("A").font(.title3) } }.padding().background(Color.white).cornerRadius(20).padding(.horizontal, 20) }; VStack(alignment: .leading, spacing: 10) { Text("Settings").font(.subhead).bold().padding(.horizontal, 25); VStack(spacing: 15) { HStack { Text("Notification"); Spacer(); Toggle("", isOn: .constant(true)).labelsHidden().tint(Color.green) }; Divider(); HStack { Text("Dark mode"); Spacer(); Toggle("", isOn: .constant(false)).labelsHidden() }; Divider(); HStack { Text("Language"); Spacer(); Text("English").foregroundColor(brandColor) } }.padding().background(Color.white).cornerRadius(20).padding(.horizontal, 20) }; Spacer() }.background(Color(.systemGroupedBackground).ignoresSafeArea()) }
}
struct MockMyExercisesDetailUI: View {
    let brandColor = Color(red: 0.38, green: 0.33, blue: 0.96)
    var body: some View { VStack(spacing: 20) { HStack { Image(systemName: "chevron.left").font(.title3).bold(); Spacer(); Text("My exercises").font(.headline); Spacer(); Image(systemName: "chevron.left").opacity(0) }.padding(.horizontal, 20).padding(.top, 60); Text("Manage your selected exercises").font(.subhead).foregroundColor(.gray); VStack(spacing: 15) { MockDetailCard(title: "Blinking", actionText: "Remove from list", actionColor: .red, actionIcon: "minus.circle.fill", btnColor: brandColor); MockDetailCard(title: "Circle", actionText: "Remove from list", actionColor: .red, actionIcon: "minus.circle.fill", btnColor: brandColor) }.padding(.top, 10); Spacer() }.background(Color(.systemGroupedBackground).ignoresSafeArea()) }
}
struct MockAllExercisesDetailUI: View {
    let brandColor = Color(red: 0.38, green: 0.33, blue: 0.96)
    var body: some View { VStack(spacing: 20) { HStack { Image(systemName: "chevron.left").font(.title3).bold(); Spacer(); Text("All exercises").font(.headline); Spacer(); Image(systemName: "chevron.left").opacity(0) }.padding(.horizontal, 20).padding(.top, 60); Text("Tap \"+\" to add to My exercise").font(.subhead).foregroundColor(.gray); VStack(spacing: 15) { MockDetailCard(title: "Blinking", actionText: "Added", actionColor: .green, actionIcon: "checkmark.circle.fill", btnColor: brandColor); MockDetailCard(title: "Circle", actionText: "Added", actionColor: .green, actionIcon: "checkmark.circle.fill", btnColor: brandColor); MockDetailCard(title: "Horizon", actionText: "Add to list", actionColor: .red, actionIcon: "plus.circle.fill", btnColor: brandColor); MockDetailCard(title: "Vertical", actionText: "Add to list", actionColor: .red, actionIcon: "plus.circle.fill", btnColor: brandColor); MockDetailCard(title: "Figure 8", actionText: "Add to list", actionColor: .red, actionIcon: "plus.circle.fill", btnColor: brandColor) }.padding(.top, 10); Spacer() }.background(Color(.systemGroupedBackground).ignoresSafeArea()) }
}
// 🔥 ДОДАНО ІМІТАЦІЮ КНОПКИ ЗВУКУ У MOCK EXERCISE UI 🔥
struct MockExerciseUI: View {
    var body: some View { ZStack { Color(.systemGroupedBackground).ignoresSafeArea(); VStack { HStack(alignment: .top) { Button(action: {}) { Circle().fill(.ultraThinMaterial).frame(width: 50, height: 50).shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2).overlay(Image(systemName: "xmark").font(.system(size: 17, weight: .semibold)).foregroundColor(.primary)) }; Spacer(); Text("Blinking").font(.system(size: 17, weight: .bold)).foregroundColor(.gray).multilineTextAlignment(.center).padding(.top, 10).offset(x: 20); Spacer(); VStack(alignment: .trailing, spacing: 12) { Button(action: {}) { HStack(spacing: 4) { Text("Tutorial").font(.subhead).bold(); Image(systemName: "questionmark.circle.fill").font(.system(size: 20)) }.foregroundColor(.primary).padding(.horizontal, 16).frame(height: 50).background(Capsule().fill(.ultraThinMaterial)).shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2) }; Button(action: {}) { Circle().fill(.ultraThinMaterial).frame(width: 50, height: 50).shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2).overlay(Image(systemName: "speaker.wave.2.fill").font(.system(size: 22)).foregroundColor(Color(hex: "6155F5"))) } } }.padding(.horizontal, 20).padding(.top, 50); Text("0 / 10").font(.system(size: 60, weight: .bold)).foregroundColor(.white).shadow(radius: 5).padding(.top, -50); Spacer() }; Ellipse().stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 4, dash: [15, 10])).frame(width: 280, height: 400).offset(y: 20) } }
}
struct MockListCard: View { var title: String; var subtitle: String; var icon: String; var iconBg: Color; var body: some View { HStack { VStack(alignment: .leading, spacing: 4) { Text(title).font(.headline); Text(subtitle).font(.subhead).foregroundColor(iconBg) }; Spacer(); Circle().fill(iconBg).frame(width: 44, height: 44).overlay(Image(systemName: icon).foregroundColor(.white)) }.padding().background(Color.white).cornerRadius(24).padding(.horizontal, 20) } }
struct MockDetailCard: View { var title: String; var actionText: String; var actionColor: Color; var actionIcon: String; var btnColor: Color; var body: some View { HStack { VStack(alignment: .leading, spacing: 4) { Text(title).font(.headline); HStack(spacing: 4) { Image(systemName: actionIcon).foregroundColor(actionColor).font(.caption); Text(actionText).font(.subhead).foregroundColor(actionColor) } }; Spacer(); Circle().fill(btnColor).frame(width: 44, height: 44).overlay(Image(systemName: "play.fill").foregroundColor(.white)) }.padding().background(Color.white).cornerRadius(20).padding(.horizontal, 20) } }

#Preview { InteractiveOnboardingView().environmentObject(UserManager()) }

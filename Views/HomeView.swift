import SwiftUI
import SwiftData

struct HomeView: View {
    @EnvironmentObject var userManager: UserManager
    @StateObject private var appData = AppData()
    @State private var showProfile = false
    
    // 👇 Зчитуємо стан темної теми з пам'яті 👇
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                MeshBackground()
                
                ScrollView {
                    VStack(spacing: 24) {
                        
                        // HEADER
                        HStack {
                            Text("EyeCoach")
                                .font(.h1)
                                .foregroundColor(.primary.opacity(0.8))
                            Spacer()
                            Button(action: {
                                showProfile = true
                            }) {
                                // 🔥 ТЕПЕР ТУТ ВІДОБРАЖАЄТЬСЯ РЕАЛЬНЕ ФОТО ЮЗЕРА 🔥
                                if let data = userManager.profileImageData, let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 50, height: 50)
                                        .clipShape(Circle())
                                        .shadow(radius: 5)
                                } else {
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .frame(width: 50, height: 50)
                                        .overlay(Image(systemName: "person.fill").foregroundColor(userManager.isUserLoggedIn ? .primaryBlue : .gray))
                                        .shadow(radius: 5)
                                }
                            }
                        }
                        .padding(.horizontal).padding(.top, 10)
                        
                        // 🔥 PROGRESS CARD 🔥
                        Button(action: {
                            if !userManager.isUserLoggedIn {
                                userManager.triggerRegistration()
                            }
                        }) {
                            ZStack(alignment: .topLeading) {
                                
                                // ШАР 1: САМА КАРТКА (З ФОНОМ ТА РАМКОЮ)
                                HStack(spacing: 0) {
                                    Image("dino")
                                        .resizable().aspectRatio(contentMode: .fit)
                                        .frame(width: 130, height: 150)
                                        .shadow(color: .black.opacity(0.2), radius: 8, y: 5)
                                        .offset(x: 10, y: 15)
                                    
                                    Spacer()
                                    
                                    // ТЕКСТ СПРАВА
                                    VStack(spacing: 0) {
                                        if !userManager.isUserLoggedIn {
                                            Text("Sign in")
                                                .font(.title).bold().foregroundColor(.primaryBlue)
                                            Text("to save progress")
                                                .font(.subheadline).foregroundColor(.primaryBlue.opacity(0.8))
                                        } else {
                                            Text("\(userManager.streakCount)")
                                                .font(.system(size: 60, weight: .bold, design: .rounded))
                                                .foregroundStyle(Color.primaryBlue)
                                            Text(userManager.streakCount == 1 ? "day streak 🔥" : "days streak 🔥")
                                                .font(.h3).foregroundColor(.primaryBlue.opacity(0.8))
                                                .padding(.top, -10)
                                        }
                                    }
                                    .padding(.trailing, 40)
                                }
                                .frame(height: 170).frame(maxWidth: .infinity)
                                .liquidGlass()
                                
                                // ШАР 2: ХМАРКА
                                if userManager.isUserLoggedIn && userManager.exercisesToday == 0 {
                                    VStack(spacing: 0) {
                                        Text("Time for your\n3 exercises! 👀")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .multilineTextAlignment(.center)
                                            .padding(8)
                                            .background(Color.white)
                                            .foregroundColor(Color(hex: "6155F5"))
                                            .cornerRadius(12)
                                            .shadow(color: .black.opacity(0.15), radius: 4, x: -5, y: -5)
                                            .offset(x: -20, y: -50)
                                        
                                        // Хвостик хмарки
                                        Triangle()
                                            .fill(Color.white)
                                            .frame(width: 12, height: 8)
                                            .rotationEffect(.degrees(180))
                                            .padding(.leading, -50)
                                            .shadow(color: .black.opacity(0.05), radius: 2, y: 25)
                                            .offset(x: -20, y: -51)
                                            .zIndex(-1)
                                    }
                                    .offset(x: 90, y: 25)
                                    .zIndex(10)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // LISTS
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Your lists").font(.h3).padding(.horizontal)
                            
                            let myQueue = appData.myExercises.isEmpty ? ["Blinking"] : appData.myExercises.map { $0.title }
                            MenuCard(
                                title: "My exercises",
                                actionText: "View list",
                                icon: "play.fill",
                                listDestination: AnyView(ExerciseListView(type: .myList, data: appData)),
                                playDestination: AnyView(WorkoutSessionView(exerciseQueue: myQueue))
                            )
                            
                            let allQueue = appData.allExercises.isEmpty ? ["Blinking"] : appData.allExercises.map { $0.title }
                            MenuCard(
                                title: "All exercises",
                                actionText: "View list",
                                icon: "play.fill",
                                listDestination: AnyView(ExerciseListView(type: .allList, data: appData)),
                                playDestination: AnyView(WorkoutSessionView(exerciseQueue: allQueue))
                            )
                            
                            let relieverQueue = appData.eyeRelieverExercises.isEmpty ? ["Blinking"] : appData.eyeRelieverExercises.map { $0.title }
                            MenuCard(
                                title: "Eye-reliever",
                                actionText: "View list",
                                icon: "play.fill",
                                listDestination: AnyView(ExerciseListView(type: .eyeReliever, data: appData)),
                                playDestination: AnyView(WorkoutSessionView(exerciseQueue: relieverQueue))
                            )
                            
                            // ВЕДЕ НА COMING SOON
                            MenuCard(
                                title: "Self sight testing",
                                actionText: "Coming soon",
                                icon: "lock.fill",
                                listDestination: AnyView(ComingSoonView(title: "Sight Testing")),
                                playDestination: AnyView(ComingSoonView(title: "Sight Testing"))
                            )
                        }
                        
                        // ARTICLE ТЕЖ ВЕДЕ НА COMING SOON
                        NavigationLink(destination: ComingSoonView(title: "Article")) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("How daily eye exercises helps you see better?")
                                    .font(.bodyBold).foregroundColor(.primary)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text("Read article").font(.subhead).foregroundColor(.primaryBlue)
                            }
                            .padding(25).frame(maxWidth: .infinity, alignment: .leading)
                            .liquidGlass().padding(.horizontal).padding(.bottom, 80)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .sheet(isPresented: $showProfile) {
                ProfileView()
                    .environmentObject(userManager)
            }
            .sheet(isPresented: $userManager.showRegistrationPopup) {
                ProfileView()
                    .environmentObject(userManager)
            }
        }
        .applySmartScale()
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}

// MENU CARD
struct MenuCard: View {
    let title: String
    let actionText: String
    let icon: String
    let listDestination: AnyView
    let playDestination: AnyView
    
    var body: some View {
        HStack {
            NavigationLink(destination: listDestination) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title).font(.bodyBold).foregroundColor(.primary)
                    Text(actionText).font(.caption).foregroundColor(.primaryBlue)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            NavigationLink(destination: playDestination) {
                Circle().fill(title == "Self sight testing" ? Color.gray : Color.primaryBlue)
                    .frame(width: 45, height: 45)
                    .overlay(Image(systemName: icon).foregroundColor(.white))
                    .shadow(color: (title == "Self sight testing" ? Color.gray : Color.blue).opacity(0.4), radius: 8, y: 5)
            }
            .disabled(title == "Self sight testing")
        }
        .padding(20).frame(maxWidth: .infinity).liquidGlass().padding(.horizontal)
    }
}

// 🔥 ВИПРАВЛЕНИЙ ЕКРАН COMING SOON З ФОНОМ 🔥
struct ComingSoonView: View {
    var title: String
    
    var body: some View {
        ZStack {
            // Додав фон, щоб більше ніякого тупо чорного екрану!
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image("dino") // Кольоровий Діно без сірих фільтрів
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150)
                    .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                
                Text("Coming Soon!")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(Color(hex: "6155F5"))
                
                Text("We are working hard to bring you the **\(title)** feature in the next update.\n\nStay tuned!")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .foregroundColor(.primary)
                    .font(.body)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// ХЕЛПЕР ДЛЯ ХМАРКИ ДІНО
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        return path
    }
}

// ПРЕВ'Ю ІЗ ФЕЙКОВИМ ЮЗЕРОМ ДЛЯ КАНВАСУ
#Preview {
    let mockUser = UserManager()
    mockUser.isUserLoggedIn = true
    mockUser.userName = "Ілона"
    mockUser.streakCount = 14
    mockUser.exercisesToday = 0
    
    return HomeView()
        .environmentObject(mockUser)
}

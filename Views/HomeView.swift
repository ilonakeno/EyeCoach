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
                            Text("EyeGym")
                                .font(.h1)
                                .foregroundColor(.primary.opacity(0.8)) // 🎨 Замінили .black на .primary
                            Spacer()
                            Button(action: {
                                showProfile = true
                            }) {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 50, height: 50)
                                    .overlay(Image(systemName: "person.fill").foregroundColor(userManager.isUserLoggedIn ? .primaryBlue : .gray))
                                    .shadow(radius: 5)
                            }
                        }
                        .padding(.horizontal).padding(.top, 10)
                        
                        // PROGRESS CARD
                        Button(action: {
                            if !userManager.isUserLoggedIn { userManager.triggerRegistration() }
                        }) {
                            HStack(spacing: 0) {
                                Image("dino")
                                    .resizable().aspectRatio(contentMode: .fit)
                                    .frame(width: 130, height: 150)
                                    .padding(.leading, -10)
                                    .shadow(color: .black.opacity(0.2), radius: 8, y: 5)
                                    .offset(x: 10)
                                Spacer()
                                VStack(spacing: 0) {
                                    Text(userManager.isUserLoggedIn ? "37" : "--")
                                        .font(.giantNumber).foregroundStyle(Color.primaryBlue)
                                    Text("days streak").font(.h3).foregroundColor(.primaryBlue.opacity(0.8))
                                }
                                .padding(.trailing, 70)
                            }
                            .frame(height: 170).frame(maxWidth: .infinity)
                            .liquidGlass().padding(.horizontal)
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
                                playDestination: AnyView(InstructionView(exerciseName: myQueue.first!, exerciseQueue: myQueue))
                            )
                            
                            let allQueue = appData.allExercises.isEmpty ? ["Blinking"] : appData.allExercises.map { $0.title }
                            MenuCard(
                                title: "All exercises",
                                actionText: "View list",
                                icon: "play.fill",
                                listDestination: AnyView(ExerciseListView(type: .allList, data: appData)),
                                playDestination: AnyView(InstructionView(exerciseName: allQueue.first!, exerciseQueue: allQueue))
                            )
                            
                            let relieverQueue = appData.eyeRelieverExercises.isEmpty ? ["Blinking"] : appData.eyeRelieverExercises.map { $0.title }
                            MenuCard(
                                title: "Eye-reliever",
                                actionText: "View list",
                                icon: "play.fill",
                                listDestination: AnyView(ExerciseListView(type: .eyeReliever, data: appData)),
                                playDestination: AnyView(InstructionView(exerciseName: relieverQueue.first!, exerciseQueue: relieverQueue))
                            )
                            
                            MenuCard(
                                title: "Self sight testing",
                                actionText: "Coming soon",
                                icon: "lock.fill",
                                listDestination: AnyView(EmptyView()),
                                playDestination: AnyView(EmptyView())
                            )
                        }
                        
                        // ARTICLE
                        VStack(alignment: .leading, spacing: 8) {
                            Text("How daily eye exercises helps you see better?")
                                .font(.bodyBold).foregroundColor(.primary) // 🎨 Замінили .black на .primary
                                .fixedSize(horizontal: false, vertical: true)
                            Text("Read article").font(.subhead).foregroundColor(.primaryBlue)
                        }
                        .padding(25).frame(maxWidth: .infinity, alignment: .leading)
                        .liquidGlass().padding(.horizontal).padding(.bottom, 80)
                    }
                }
            }
            .sheet(isPresented: $showProfile) {
                ProfileView()
                    .environmentObject(userManager)
            }
        }
        .applySmartScale()
        // ✨ МАГІЯ ТЕМНОЇ ТЕМИ: примусово вмикає ту тему, яка вибрана в налаштуваннях ✨
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
                    Text(title).font(.bodyBold).foregroundColor(.primary) // 🎨 Замінили .black на .primary
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

#Preview {
    HomeView()
        .environmentObject(UserManager())
}

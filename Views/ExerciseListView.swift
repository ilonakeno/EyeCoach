import SwiftUI

struct ExerciseListView: View {
    @Environment(\.dismiss) var dismiss
    
    var type: ListType
    @ObservedObject var data: AppData
    
    var displayedExercises: [ExerciseItem] {
        switch type {
        case .myList: return data.myExercises
        case .allList: return data.allExercises
        case .eyeReliever: return data.eyeRelieverExercises
        }
    }
    
    var pageTitle: String {
        switch type {
        case .myList: return "My exercises"
        case .allList: return "All exercises"
        case .eyeReliever: return "Eye-reliever"
        }
    }
    
    var pageSubtitle: String {
        switch type {
        case .myList: return "Manage your selected exercises"
        case .allList: return "Tap \"+\" to add to My exercise"
        case .eyeReliever: return "Quick relaxation for your eyes"
        }
    }
    
    var body: some View {
        ZStack {
            // 🎨 Розумний фон: світло-сірий вдень, глибокий чорний вночі
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            VStack(spacing: 0) {
                ZStack {
                    Text(pageTitle)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary) // 🎨 Був .black
                    
                    HStack {
                        Button(action: { dismiss() }) {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.primary) // 🎨
                                )
                        }
                        Spacer()
                    }
                }
                .padding(.horizontal, 20).padding(.top, 10)
                
                Text(pageSubtitle)
                    .font(.caption)
                    .foregroundColor(.secondary) // 🎨 Розумний сірий
                    .padding(.top, 15).padding(.bottom, 30)
                
                ScrollView {
                    VStack(spacing: 16) {
                        if displayedExercises.isEmpty {
                            Text("No exercises added yet.")
                                .foregroundColor(.gray).padding(.top, 50)
                        } else {
                            ForEach(displayedExercises) { exercise in
                                ExerciseListRow(
                                    exercise: exercise,
                                    listType: type,
                                    onToggle: {
                                        withAnimation { data.toggleAdd(for: exercise) }
                                    }
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20).padding(.bottom, 50)
                }
            }
        }
        .navigationBarHidden(true)
        .applySmartScale() // ✨ Додаємо масштабування тексту і сюди!
    }
}

struct ExerciseListRow: View {
    var exercise: ExerciseItem
    var listType: ListType
    var onToggle: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(exercise.title)
                    .font(.bodyBold)
                    .foregroundColor(.primary) // 🎨
                
                if listType != .eyeReliever {
                    Button(action: onToggle) {
                        HStack(spacing: 4) {
                            if listType == .myList {
                                Image(systemName: "minus.circle.fill").foregroundColor(.red)
                                Text("Remove from list").font(.caption).foregroundColor(.red)
                            } else {
                                Image(systemName: exercise.isAdded ? "checkmark.circle.fill" : "plus.circle.fill")
                                    .foregroundColor(exercise.isAdded ? .green : .red)
                                Text(exercise.isAdded ? "Added" : "Add to list")
                                    .font(.caption)
                                    .foregroundColor(exercise.isAdded ? .green : .gray)
                            }
                        }
                    }
                } else {
                    Text("Relaxing exercise")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            NavigationLink(destination: InstructionView(exerciseName: exercise.title)) {
                Circle()
                    .fill(Color.primaryBlue)
                    .frame(width: 44, height: 44)
                    .overlay(Image(systemName: "play.fill").foregroundColor(.white).font(.system(size: 16)))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .liquidGlass() // ✨ Наше нове адаптивне скло!
    }
}

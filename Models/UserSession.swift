//
//  UserSession.swift
//  EyeGym
//
//  Created by Ilona Keno on 23.01.2026.
//

import Foundation
import SwiftData

// @Model каже системі: "Це треба зберігати в пам'яті телефону та iCloud"
@Model
final class UserSession {
    var id: UUID
    var date: Date
    var exerciseName: String
    var isCompleted: Bool
    
    init(exerciseName: String, isCompleted: Bool = true) {
        self.id = UUID()
        self.date = Date()
        self.exerciseName = exerciseName
        self.isCompleted = isCompleted
    }
}

//
//  PermissionsView.swift
//  EyeGym
//
//  Created by Ilona Keno on 20.02.2026.
//

import SwiftUI
import AVFoundation // Для камери
import UserNotifications // Для сповіщень

struct PermissionsView: View {
    @Environment(\.dismiss) var dismiss
    
    // Зберігаємо стани тумблерів
    @AppStorage("hasCameraAccess") var hasCameraAccess: Bool = false
    @AppStorage("hasNotificationAccess") var hasNotificationAccess: Bool = false
    @AppStorage("hasScreenTimeAccess") var hasScreenTimeAccess: Bool = false // Поки що концептуальний
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            VStack(spacing: 24) {
                // ШАПКА
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                            .frame(width: 40, height: 40)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(Circle())
                    }
                    Spacer()
                    Text("Permissions")
                        .font(.h3)
                        .foregroundColor(.primary)
                    Spacer()
                    Color.clear.frame(width: 40, height: 40) // Баланс
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // ОПИС
                Text("Allow EyeGym to help you build healthy habits and protect your vision.")
                    .font(.bodyRegular)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                
                // СПИСОК ДОЗВОЛІВ
                VStack(spacing: 16) {
                    
                    // 1. КАМЕРА
                    PermissionCard(
                        icon: "camera.fill",
                        color: .blue,
                        title: "Camera Access",
                        description: "Required to track your eye movements during AR exercises.",
                        isOn: $hasCameraAccess,
                        action: requestCameraPermission
                    )
                    
                    // 2. СПОВІЩЕННЯ (ДЛЯ НАГАДУВАНЬ ЩОГОДИНИ)
                    PermissionCard(
                        icon: "bell.badge.fill",
                        color: .red,
                        title: "Smart Reminders",
                        description: "We will remind you to blink and relax your eyes every hour.",
                        isOn: $hasNotificationAccess,
                        action: requestNotificationPermission
                    )
                    
                    // 3. SCREEN TIME (КОНЦЕПТ)
                    PermissionCard(
                        icon: "hourglass",
                        color: Color(hex: "6155F5"), // Твій фірмовий
                        title: "Screen Time Tracking",
                        description: "Analyze your phone usage to send reminders at the right time.",
                        isOn: $hasScreenTimeAccess,
                        action: { hasScreenTimeAccess.toggle() }
                    )
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .applySmartScale()
    }
    
    // --- ФУНКЦІЇ ДЛЯ ЗАПИТУ ДОЗВОЛІВ У IOS ---
    
    func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                self.hasCameraAccess = granted
            }
        }
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.hasNotificationAccess = granted
                if granted {
                    scheduleHourlyReminder() // Запускаємо нагадування, якщо юзер дозволив
                }
            }
        }
    }
    
    func scheduleHourlyReminder() {
        let content = UNMutableNotificationContent()
        content.title = "Time to relax your eyes! 👀"
        content.body = "You've been looking at the screen for a while. Let's do a quick blinking exercise."
        content.sound = UNNotificationSound.default
        
        // Нагадувати кожні 3600 секунд (1 година)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: true)
        let request = UNNotificationRequest(identifier: "hourlyEyeReminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
}

// КАРТКА ОДНОГО ДОЗВОЛУ
struct PermissionCard: View {
    var icon: String
    var color: Color
    var title: String
    var description: String
    @Binding var isOn: Bool
    var action: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Іконка
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.system(size: 20, weight: .semibold))
                )
            
            // Текст
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.bodyBold)
                    .foregroundColor(.primary)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            // Кнопка увімкнення
            Toggle("", isOn: Binding(
                get: { isOn },
                set: { _ in action() } // Викликаємо запит при кліку
            ))
            .labelsHidden()
            .tint(Color(hex: "6155F5"))
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(20)
    }
}

#Preview {
    PermissionsView()
}

//
//  Timer.swift
//  tomato Watch App
//
//  Created by Mano Rajesh on 11/3/24.
//

import SwiftUI
import Combine
import UserNotifications

struct TimerView: View {
    @ObservedObject var timerModel: TimerModel
    
    private func formatTime(seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
    
    var body: some View {
        BreathingGradient().brightness(0.3).mask() {
            Text(formatTime(seconds: timerModel.timeRemaining))
                .contentTransition(.numericText())
                .font(.system(size: 55, weight: timerModel.isActive ? .semibold : .ultraLight, design: .monospaced))
                .foregroundStyle(.white)
                .animation(.easeInOut(duration: 0.3), value: timerModel.isActive)
                .blur(radius: timerModel.isActive ? 0.8 : 0.2)
        }
    }
}

extension Text {
    public func foregroundLinearGradient(
        colors: [Color],
        startPoint: UnitPoint,
        endPoint: UnitPoint) -> some View {
            self.overlay {
                LinearGradient(
                    colors: colors,
                    startPoint: startPoint,
                    endPoint: endPoint
                )
                .mask(self)
            }
        }
}

class TimerModel: ObservableObject {
    var breakTime: Int
    var focusTime: Int
    @Published var timeRemaining: Int
    @Published var isActive = false
    @Published var isWorkSession = true
    
    private var timer: AnyCancellable?
    
    init(focusTime: Int = 25*60, breakTime: Int = 5*60) {
        self.breakTime = breakTime
        self.focusTime = focusTime
        self.timeRemaining = self.focusTime
        requestNotificationPermission()
    }
    
    func start() {
        withAnimation {
            isActive = true
        }
        scheduleSessionEndNotification()
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }
    
    func stop() {
        timer?.cancel()
        removePendingNotifications()
        withAnimation {
            isActive = false
        }
    }
    
    func tick() {
        guard timeRemaining > 0 else {
            switchSession()
            return
        }
        withAnimation {
            timeRemaining -= 1
        }
    }
    
    func increment(by sec: Int) {
        let result = self.timeRemaining + sec
        if result <= 0 || result > focusTime {
            return
        }
        timeRemaining += sec
        scheduleSessionEndNotification()
    }
    
    func reset() {
        self.stop()
        withAnimation {
            timeRemaining = focusTime
        }
    }
    
    private func switchSession() {
        isWorkSession.toggle()
        withAnimation {
            timeRemaining = isWorkSession ? focusTime : breakTime
        }
        scheduleSessionEndNotification() // Schedule a new notification for the new session
    }
    
    // MARK: - Notification Methods
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Error requesting notification permission: \(error.localizedDescription)")
            }
        }
    }
    
    private func scheduleSessionEndNotification() {
        removePendingNotifications() // Clear any existing notifications to avoid duplicates
        
        let content = UNMutableNotificationContent()
        content.title = isWorkSession ? "Break Time!" : "Focus Session Started"
        content.body = isWorkSession ? "Your focus session has ended. Time for a break!" : "Break is over. Time to focus!"
        content.sound = .default
        
        // Schedule the notification for when the session ends
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(timeRemaining), repeats: false)
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to add notification: \(error.localizedDescription)")
            }
        }
    }
    
    private func removePendingNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}

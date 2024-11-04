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
        BreathingGradient(usePrimaryColors: $timerModel.isWorkSession).brightness(0.3).mask {
            Text(formatTime(seconds: timerModel.timeRemaining))
                .contentTransition(.numericText())
                .font(.system(size: 70, weight: timerModel.isActive ? .semibold : .ultraLight, design: .rounded))
                .foregroundStyle(.white)
                .animation(.easeInOut(duration: 0.3), value: timerModel.isActive)
                .blur(radius: timerModel.isActive ? 0.8 : 0.2)
        }
    }
}

class TimerModel: ObservableObject {
    var breakTime: Int
    var focusTime: Int
    @Published var timeRemaining: Int
    @Published var isActive = false
    @Published var isWorkSession = true

    var timer: AnyCancellable?
    private var startTime: Date?
    private var endTime: Date?

    init(focusTime: Int = 25*60, breakTime: Int = 5*60) {
        self.focusTime = focusTime
        self.breakTime = breakTime
        self.timeRemaining = focusTime
        requestNotificationPermission()
    }

    func start() {
        withAnimation {
            isActive = true
        }
        startTime = Date()
        endTime = Date().addingTimeInterval(TimeInterval(timeRemaining))
        scheduleSessionEndNotification()
        startTimer()
    }

    func stop() {
        timer?.cancel()
        removePendingNotifications()
        withAnimation {
            isActive = false
        }
    }

    func reset() {
        stop()
        withAnimation {
            timeRemaining = isWorkSession ? focusTime : breakTime
        }
    }

    func increment(by sec: Int) {
        guard let endTime = endTime else { return }

        let newEndTime = endTime.addingTimeInterval(TimeInterval(sec))
        let newTimeRemaining = Int(newEndTime.timeIntervalSinceNow)

        // Ensure the new time is within valid bounds
        let maxTime = isWorkSession ? focusTime : breakTime
        if newTimeRemaining < 0 || newTimeRemaining > maxTime {
            return
        }

        self.endTime = newEndTime
        self.timeRemaining = newTimeRemaining

        // Reschedule notification
        scheduleSessionEndNotification()
    }

    func startTimer() {
        // Update timeRemaining every second while app is in foreground
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateTimeRemaining()
            }
    }

    func updateTimeRemaining() {
        guard let endTime = endTime else { return }

        let remaining = Int(endTime.timeIntervalSinceNow)
        if remaining <= 0 {
            timeRemaining = 0
            switchSession()
        } else {
            withAnimation {
                timeRemaining = remaining
            }
        }
    }

    private func switchSession() {
        withAnimation {
            isWorkSession.toggle()
            timeRemaining = isWorkSession ? focusTime : breakTime
        }
        startTime = Date()
        endTime = Date().addingTimeInterval(TimeInterval(timeRemaining))
        scheduleSessionEndNotification()
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
        removePendingNotifications()

        guard let endTime = endTime else { return }

        let content = UNMutableNotificationContent()
        content.title = isWorkSession ? "cool down" : "time to focus"
        content.body = isWorkSession ? "it's time for a break" : "get to work; break is over"
        content.sound = .default

        let timeInterval = endTime.timeIntervalSinceNow
        if timeInterval > 0 {
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)

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
    }

    private func removePendingNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}

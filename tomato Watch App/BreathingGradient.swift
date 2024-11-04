//
//  BreathingGradient.swift
//  tomato Watch App
//
//  Created by Mano Rajesh on 11/3/24.
//

import SwiftUI

struct BreathingGradient: View {
    @State private var animateGradient = false
    @State private var gradientCenter: UnitPoint = .center
    @Binding var usePrimaryColors: Bool

    var body: some View {
        RadialGradient(
            gradient: usePrimaryColors ? Gradient(colors: [
                .blue, .purple, .pink, .red, .yellow
            ]) : Gradient(colors: [
                .cyan, .indigo, .teal, .green, .orange
            ]),
            center: gradientCenter,
            startRadius: 0,
            endRadius: 360
        )
        .blur(radius: 30)
        .opacity(0.8)
        .animation(
            .easeInOut(duration: 1).repeatForever(autoreverses: true),
            value: gradientCenter
        )
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            startRandomAnimation()
        }
    }

    private func startRandomAnimation() {
        // Start a timer that updates the gradient center periodically
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            withAnimation {
                gradientCenter = randomUnitPoint()
            }
        }
    }

    // Generate a random UnitPoint for the gradient's center
    private func randomUnitPoint() -> UnitPoint {
        UnitPoint(x: Double.random(in: 0...1), y: Double.random(in: 0...1))
    }
}

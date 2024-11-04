//
//  ContentView.swift
//  tomato Watch App
//
//  Created by Mano Rajesh on 10/29/24.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var timerModel = TimerModel()
    @State private var crownValue = 0.0
    @State private var prevCrownValue = 0.0
    @State private var isShowing = false
    @State private var animationIsActive = true
    @State private var isEditingTime = false
    @State private var selectedFocusTime = 25 // in minutes
    @State private var selectedBreakTime = 5 // in minutes
    
    var body: some View {
        ZStack {
            if timerModel.isActive {
                BreathingGradient().mask() {
                    Circle().blur(radius: 30.0)
                }
            }
            
            VStack {
                if !timerModel.isActive {
                    HStack {
                        Spacer()
                        Text("\(timerModel.breakTime/60) min break")
                            .font(.caption)
                            .opacity(0.5)
                            .padding(.trailing)
                    }
                    .transition(.slideAndFade(edge: .bottom))
                }
                
                TimerView(timerModel: timerModel)
                    .onTapGesture {
                        toggleTimer()
                    }
                    .focusable()
                    .digitalCrownRotation($crownValue, from: -1000.0, through: 1000.0, isContinuous: true, isHapticFeedbackEnabled: true)
                    .onChange(of: crownValue) {
                        let result = crownValue - prevCrownValue > 0 ? 1 : -1
                        timerModel.increment(by: result)
                        prevCrownValue = crownValue
                    }
                    .confirmationDialog("End Pomodoro?", isPresented: $isShowing) {
                        Button("Bye", role: .destructive) { timerModel.reset() }
                    }
                
                if !timerModel.isActive {
                    HStack {
                        Image(systemName: "x.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .font(.system(size: 40, weight: .light))
                            .padding()
                            .padding(.trailing, 20)
                            .onTapGesture() {
                                isShowing.toggle()
                            }
                        
                        Image(systemName: "pencil.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .font(.system(size: 40, weight: .light))
                            .padding()
                            .onTapGesture {
                                isEditingTime.toggle() // Show the time editor sheet
                            }
                    }
                    .background(BreathingGradient().opacity(0.6))
                }
            }
            
        }
        .sheet(isPresented: $isEditingTime) {
            TimeEditor(
                selectedFocusTime: $selectedFocusTime,
                selectedBreakTime: $selectedBreakTime,
                onSave: {
                    timerModel.focusTime = selectedFocusTime * 60
                    timerModel.breakTime = selectedBreakTime * 60
                    timerModel.reset()
                    isEditingTime = false
                }
            )
        }
    }
    
    func toggleTimer() {
        timerModel.isActive ? timerModel.stop() : timerModel.start()
    }
}

extension AnyTransition {
    static func slideAndFade(edge: Edge) -> AnyTransition {
        AnyTransition
            .opacity
            .combined(with: .move(edge: edge))
    }
}

#Preview {
    ContentView()
}

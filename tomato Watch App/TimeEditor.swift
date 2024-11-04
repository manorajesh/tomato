//
//  TimeEditor.swift
//  tomato Watch App
//
//  Created by Mano Rajesh on 11/3/24.
//

import SwiftUI

struct TimeEditor: View {
    @Binding var selectedFocusTime: Int
    @Binding var selectedBreakTime: Int
    var onSave: () -> Void

    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Picker("Focus Time", selection: $selectedFocusTime) {
                        ForEach(0...60, id: \.self) { time in
                            Text("\(time) min")
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    Picker("Break Time", selection: $selectedBreakTime) {
                        ForEach(0...60, id: \.self) { time in
                            Text("\(time) min")
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                }
                .navigationTitle("Edit Timer")
                
                Button {
                    onSave()
                } label: {
                    Text("Save")
                }
                .disabled(selectedFocusTime == 0)
                .opacity(selectedFocusTime == 0 ? 0.4 : 1.0)
            }
        }
        .background(BreathingGradient().opacity(0.2))
    }
}
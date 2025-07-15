//
//  ViewModeToggle.swift
//  Meal Planner
//
//  Created by Tj Manzoni on 10/07/2025.
//

import SwiftUI

struct ViewModeToggle: View {
    @Binding var isDayView: Bool

    var body: some View {
        HStack {
            Button(action: { isDayView = true }) {
                Text("Day")
                    .font(.body) // Larger toggle text
                    .fontWeight(isDayView ? .bold : .regular)
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(isDayView ? Color.buttonBackground : Color.clear) // Coral when selected
                    .cornerRadius(8)
            }
            
            Button(action: { isDayView = false }) {
                Text("Week")
                    .font(.body) // Larger toggle text
                    .fontWeight(!isDayView ? .bold : .regular)
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(!isDayView ? Color.buttonBackground : Color.clear) // Coral when selected
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 4)
    }
} 
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
                    .font(.caption)
                    .fontWeight(isDayView ? .bold : .regular)
                    .foregroundColor(isDayView ? .white : .blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(isDayView ? Color.blue : Color.clear)
                    .cornerRadius(8)
            }
            
            Button(action: { isDayView = false }) {
                Text("Week")
                    .font(.caption)
                    .fontWeight(!isDayView ? .bold : .regular)
                    .foregroundColor(!isDayView ? .white : .blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(!isDayView ? Color.blue : Color.clear)
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 4)
    }
} 
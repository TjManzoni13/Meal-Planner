//
//  DaySelectorView.swift
//  Meal Planner
//
//  Created by Tj Manzoni on 10/07/2025.
//

import SwiftUI

struct DaySelectorView: View {
    @Binding var selectedDayIndex: Int
    let days: [String]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<days.count, id: \.self) { idx in
                Button(action: {
                    selectedDayIndex = idx
                }) {
                    Text(days[idx])
                        .font(.system(size: 13, weight: selectedDayIndex == idx ? .bold : .regular))
                        .foregroundColor(selectedDayIndex == idx ? .white : .blue)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(selectedDayIndex == idx ? Color.blue : Color.clear)
                        .cornerRadius(8)
                }
            }
        }
        .padding(.horizontal)
    }
} 
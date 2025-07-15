//
//  WeekNavigation.swift
//  Meal Planner
//
//  Created by Tj Manzoni on 10/07/2025.
//

import SwiftUI

struct WeekNavigation: View {
    @Binding var selectedWeekStart: Date
    var onWeekChange: (Date) -> Void
    var weekRangeText: String
    
    // Calculate the earliest allowed week (4 weeks ago from current week)
    private var earliestAllowedWeek: Date {
        let currentWeekStart = Calendar.current.startOfWeek(for: Date())
        return Calendar.current.date(byAdding: .weekOfYear, value: -4, to: currentWeekStart) ?? currentWeekStart
    }
    
    var body: some View {
        HStack {
            Button(action: {
                let newStart = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: selectedWeekStart).map { Calendar.current.startOfWeek(for: $0) } ?? selectedWeekStart
                
                // Only allow going back if we're not already at the earliest allowed week
                if newStart >= earliestAllowedWeek {
                    onWeekChange(newStart)
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(selectedWeekStart <= earliestAllowedWeek ? .gray : Color.buttonBackground) // Use coral when enabled
            }
            .disabled(selectedWeekStart <= earliestAllowedWeek)
            
            Spacer()
            Text(weekRangeText)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.black) // Black text
            Spacer()
            Button(action: {
                let newStart = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: selectedWeekStart).map { Calendar.current.startOfWeek(for: $0) } ?? selectedWeekStart
                onWeekChange(newStart)
            }) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(Color.buttonBackground) // Use coral
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 4)
    }
} 
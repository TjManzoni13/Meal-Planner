//
//  DayColumnView.swift
//  Meal Planner
//
//  Created by Tj Manzoni on 10/07/2025.
//

import SwiftUI

struct DayColumnView: View {
    let date: Date
    let mealSlots: [String]
    let meals: [Meal]
    let day: MealDay
    let onMealSelected: (Meal, String) -> Void
    let onManualIngredient: (String) -> Void
    
    @State private var showingMealPicker = false
    @State private var selectedSlot: String = ""
    @State private var manualIngredient = ""
    @State private var showingManualInput = false
    @Binding var selectedTab: Int // Pass this down for tab switching
    @EnvironmentObject var weekPlanManager: WeekPlanManager

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Full day name and UK date, centered
            HStack {
                Spacer()
                Text(fullDayUKString(for: date))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                Spacer()
            }
            .padding(.bottom, 4)

            // "Already have" checkbox
            HStack {
                Button(action: {
                    weekPlanManager.toggleAlreadyHave(for: day)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: day.alreadyHave ? "checkmark.square.fill" : "square")
                            .foregroundColor(day.alreadyHave ? .green : .gray)
                            .font(.caption)
                        Text("Already have")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                Spacer()
            }
            .padding(.bottom, 4)
            .onChange(of: day.alreadyHave) { _, _ in
                // Force UI update when alreadyHave changes
            }

            // Meal slots
            ForEach(mealSlots, id: \.self) { slot in
                MealSlotView(
                    slot: slot,
                    day: day,
                    meals: meals,
                    onMealSelected: onMealSelected,
                    onManualIngredient: onManualIngredient,
                    selectedTab: $selectedTab // Pass the binding
                )
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }

    // Full day name and UK date: Monday 7th July 2025
    private func fullDayUKString(for date: Date) -> String {
        let dayFormatter = DateFormatter()
        dayFormatter.locale = Locale(identifier: "en_GB")
        dayFormatter.dateFormat = "EEEE d MMMM yyyy"
        let dayString = dayFormatter.string(from: date)
        // Add ordinal suffix to day
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        let suffix = ordinalSuffix(for: day)
        let comps = dayString.components(separatedBy: " ")
        if comps.count >= 2 {
            return comps[0] + " " + String(day) + suffix + " " + comps[2...].joined(separator: " ")
        } else {
            return dayString
        }
    }

    private func ordinalSuffix(for day: Int) -> String {
        if (11...13).contains(day % 100) { return "th" }
        switch day % 10 {
        case 1: return "st"
        case 2: return "nd"
        case 3: return "rd"
        default: return "th"
        }
    }
} 
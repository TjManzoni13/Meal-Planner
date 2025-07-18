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
    let textColor: Color // New parameter for text color

    init(date: Date, mealSlots: [String], meals: [Meal], day: MealDay, onMealSelected: @escaping (Meal, String) -> Void, onManualIngredient: @escaping (String) -> Void, selectedTab: Binding<Int>, textColor: Color = .primary) {
        self.date = date
        self.mealSlots = mealSlots
        self.meals = meals
        self.day = day
        self.onMealSelected = onMealSelected
        self.onManualIngredient = onManualIngredient
        self._selectedTab = selectedTab
        self.textColor = textColor
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Full day name and UK date, centered
            HStack {
                Spacer()
                Text(fullDayUKString(for: date))
                    .font(.title3) // Larger date
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(textColor)
                Spacer()
            }
            .padding(.bottom, 4)

            // Meal slots with individual "already have" checkboxes
            ForEach(mealSlots, id: \.self) { slot in
                VStack(alignment: .leading, spacing: 4) {
                    // Meal slot view
                    MealSlotView(
                        slot: slot,
                        day: day,
                        meals: meals,
                        onMealSelected: onMealSelected,
                        onManualIngredient: onManualIngredient,
                        selectedTab: $selectedTab, // Pass the binding
                        textColor: textColor // Pass text color
                    )
                }
            }
        }
        .padding(8)
        .background(Color.appBackground.opacity(0.8)) // Use app background with some opacity
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.accent, lineWidth: 2) // Accent border
        )
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
//
//  MealSlotPicker.swift
//  Meal Planner
//
//  Created by Tj Manzoni on 10/07/2025.
//


import SwiftUI

struct MealSlotPicker: View {
    let slot: String
    @ObservedObject var day: MealDay
    let meals: [Meal]
    let onSelect: (Meal) -> Void

    @State private var selectedMeal: Meal?

    var body: some View {
        Menu {
            ForEach(filteredMeals(), id: \.self) { meal in
                Button(meal.name ?? "") {
                    selectedMeal = meal
                    onSelect(meal)
                }
            }
        } label: {
            HStack {
                Text(selectedMeal?.name ?? "Select \(slot)...")
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.down")
                    .foregroundColor(.gray)
            }
            .padding(8)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(6)
        }
        .onAppear {
            selectedMeal = mealForSlot()
        }
    }

    private func filteredMeals() -> [Meal] {
        return meals.filter { meal in
            guard let tags = meal.tags?.lowercased() else { return false }
            return tags.contains(slot.lowercased()) || tags.contains("all")
        }
    }

    private func mealForSlot() -> Meal? {
        switch slot.lowercased() {
        case "breakfast": return day.breakfast
        case "lunch": return day.lunch
        case "dinner": return day.dinner
        case "other": return day.other
        default: return nil
        }
    }
}

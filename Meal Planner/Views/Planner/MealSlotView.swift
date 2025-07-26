//
//  MealSlotView.swift
//  Meal Planner
//
//  Created by Tj Manzoni on 10/07/2025.
//

import SwiftUI

struct MealSlotView: View {
    let slot: String
    let day: MealDay
    let meals: [Meal]
    let onMealSelected: (Meal, String) -> Void
    let onManualIngredient: (String) -> Void
    @Binding var selectedTab: Int
    @State private var showingMealPicker = false
    @State private var manualIngredient = ""
    @State private var showingManualInput = false
    @State private var mealSearch = ""
    @EnvironmentObject var weekPlanManager: WeekPlanManager
    let textColor: Color // New parameter for text color

    init(slot: String, day: MealDay, meals: [Meal], onMealSelected: @escaping (Meal, String) -> Void, onManualIngredient: @escaping (String) -> Void, selectedTab: Binding<Int>, textColor: Color = .primary) {
        self.slot = slot
        self.day = day
        self.meals = meals
        self.onMealSelected = onMealSelected
        self.onManualIngredient = onManualIngredient
        self._selectedTab = selectedTab
        self.textColor = textColor
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .center, spacing: 8) {
                Text(slot)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(textColor)
                Spacer()
                // Inline 'Ingredients at Home' checkbox with black border
                Button(action: {
                    weekPlanManager.toggleAlreadyHave(for: day, slot: slot)
                }) {
                    HStack(spacing: 4) {
                        ZStack {
                            // Checkbox fill: transparent when unchecked, coral when checked
                            RoundedRectangle(cornerRadius: 4)
                                .fill(weekPlanManager.getAlreadyHave(for: day, slot: slot) ? Color.buttonBackground : Color.clear)
                                .frame(width: 18, height: 18)
                            // Checkmark
                            if weekPlanManager.getAlreadyHave(for: day, slot: slot) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.black)
                                    .font(.system(size: 12, weight: .bold))
                            }
                            // Black border
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.black, lineWidth: 2)
                                .frame(width: 18, height: 18)
                        }
                        Text("Ingredients at Home")
                            .font(.callout) // Larger label
                            .foregroundColor(textColor)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }

            // Show manual slot ingredients for this day/slot
            ForEach(weekPlanManager.fetchManualSlotIngredients(for: slot, date: day.date ?? Date()), id: \.id) { ing in
                if let name = ing.name {
                    HStack {
                        Image(systemName: "pencil")
                            .foregroundColor(Color.accent)
                        Text(name)
                            .font(.body) // Larger manual ingredient
                            .foregroundColor(textColor)
                        Spacer()
                        Button(action: {
                            weekPlanManager.deleteManualSlotIngredient(ing)
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(Color.buttonBackground)
                                .font(.caption)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.vertical, 2)
                }
            }

            // Show all meals for this slot
            ForEach(getCurrentMeals(), id: \.self) { meal in
                HStack {
                    Image(systemName: "fork.knife")
                        .foregroundColor(Color.accent)
                    Text(meal.name ?? "")
                        .font(.body) // Match manual ingredients font
                        .foregroundColor(textColor)
                    Spacer()
                    Button(action: {
                        weekPlanManager.removeMeal(meal, from: day, slot: slot)
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(Color.buttonBackground)
                            .font(.caption)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.vertical, 2)
            }

            // Always show the Add meal button
            Button(action: {
                showingMealPicker = true
            }) {
                HStack {
                    Image(systemName: "plus.circle")
                        .font(.caption)
                        .foregroundColor(Color.accent)
                    Text("Add meal")
                        .font(.callout) // Larger add meal button
                        .foregroundColor(textColor)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(6)
                .background(Color.buttonBackground)
                .cornerRadius(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.accent, lineWidth: 2)
                )
            }
            .sheet(isPresented: $showingMealPicker) {
                MealPickerSheet(
                    meals: meals,
                    search: $mealSearch,
                    onSelect: { meal in
                        onMealSelected(meal, slot)
                        // Don't dismiss the sheet - allow multiple selections
                    },
                    onCreateNew: {
                        selectedTab = 2 // Switch to Meals tab
                        showingMealPicker = false
                    },
                    onManualIngredient: { ingredient in
                        // Save manual slot ingredient to Core Data
                        weekPlanManager.addManualSlotIngredient(name: ingredient, slot: slot, date: day.date ?? Date())
                        // Don't dismiss the sheet - allow multiple additions
                    }
                )
            }
        }
    }

    // Return all meals for the slot as an array
    private func getCurrentMeals() -> [Meal] {
        let result: [Meal]
        switch slot.lowercased() {
        case "breakfast": 
            result = (day.breakfasts as? Set<Meal>)?.sorted { ($0.name ?? "") < ($1.name ?? "") } ?? []
            print("Breakfast meals for \(slot): \(result.count) meals")
        case "lunch": 
            result = (day.lunches as? Set<Meal>)?.sorted { ($0.name ?? "") < ($1.name ?? "") } ?? []
            print("Lunch meals for \(slot): \(result.count) meals")
        case "dinner": 
            result = (day.dinners as? Set<Meal>)?.sorted { ($0.name ?? "") < ($1.name ?? "") } ?? []
            print("Dinner meals for \(slot): \(result.count) meals")
        case "other": 
            result = (day.others as? Set<Meal>)?.sorted { ($0.name ?? "") < ($1.name ?? "") } ?? []
            print("Other meals for \(slot): \(result.count) meals")
        default: 
            result = []
            print("Unknown slot: \(slot)")
        }
        return result
    }
} 
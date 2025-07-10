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
    @State private var ingredientsAlreadyHave = false
    @State private var mealSearch = ""
    @EnvironmentObject var weekPlanManager: WeekPlanManager

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(slot)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            // Show manual slot ingredients for this day/slot
            ForEach(weekPlanManager.fetchManualSlotIngredients(for: slot, date: day.date ?? Date()), id: \.id) { ing in
                if let name = ing.name {
                    HStack {
                        Image(systemName: "pencil")
                            .foregroundColor(.gray)
                        Text(name)
                            .font(.caption)
                            .foregroundColor(.primary)
                        Spacer()
                        Button(action: {
                            weekPlanManager.deleteManualSlotIngredient(ing)
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.vertical, 2)
                }
            }

            if let currentMeal = getCurrentMeal() {
                VStack(alignment: .leading, spacing: 2) {
                    Text(currentMeal.name ?? "")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    // "Ingredients already have" checkbox
                    HStack {
                        Image(systemName: ingredientsAlreadyHave ? "checkmark.square.fill" : "square")
                            .foregroundColor(ingredientsAlreadyHave ? .green : .gray)
                            .font(.caption)
                        
                        Text("Have ingredients")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .onTapGesture {
                        ingredientsAlreadyHave.toggle()
                    }
                }
                .padding(6)
                .background(Color.green.opacity(0.1))
                .cornerRadius(4)
                .onTapGesture {
                    showingMealPicker = true
                }
            } else {
                Button(action: {
                    showingMealPicker = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle")
                            .font(.caption)
                        Text("Add meal")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
                }
                .sheet(isPresented: $showingMealPicker) {
                    MealPickerSheet(
                        meals: meals,
                        search: $mealSearch,
                        onSelect: { meal in
                            onMealSelected(meal, slot)
                            showingMealPicker = false
                        },
                        onCreateNew: {
                            selectedTab = 2 // Switch to Meals tab
                            showingMealPicker = false
                        },
                        onManualIngredient: { ingredient in
                            // Save manual slot ingredient to Core Data
                            weekPlanManager.addManualSlotIngredient(name: ingredient, slot: slot, date: day.date ?? Date())
                            showingMealPicker = false
                        }
                    )
                }
            }
        }
    }

    private func getCurrentMeal() -> Meal? {
        switch slot.lowercased() {
        case "breakfast": return day.breakfast
        case "lunch": return day.lunch
        case "dinner": return day.dinner
        case "other": return day.other
        default: return nil
        }
    }
} 
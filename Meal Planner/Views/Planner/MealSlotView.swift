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

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(slot)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Color.accent) // Use accent for slot title

            // Show manual slot ingredients for this day/slot
            ForEach(weekPlanManager.fetchManualSlotIngredients(for: slot, date: day.date ?? Date()), id: \.id) { ing in
                if let name = ing.name {
                    HStack {
                        Image(systemName: "pencil")
                            .foregroundColor(Color.accent)
                        Text(name)
                            .font(.caption)
                            .foregroundColor(Color.mainText)
                        Spacer()
                        Button(action: {
                            weekPlanManager.deleteManualSlotIngredient(ing)
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(Color.accent)
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
                    Text(meal.name ?? "")
                        .font(.caption)
                        .fontWeight(.medium)
                    Spacer()
                    Button(action: {
                        weekPlanManager.removeMeal(meal, from: day, slot: slot)
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(6)
                .background(Color.green.opacity(0.1))
                .cornerRadius(4)
            }

            // "Have ingredients" checkbox (applies to the whole slot)
            HStack {
                Image(systemName: weekPlanManager.getAlreadyHave(for: day, slot: slot) ? "checkmark.square.fill" : "square")
                    .foregroundColor(weekPlanManager.getAlreadyHave(for: day, slot: slot) ? .green : .gray)
                    .font(.caption)
                Text("Have ingredients")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .onTapGesture {
                weekPlanManager.toggleAlreadyHave(for: day, slot: slot)
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
                        .font(.caption)
                        .foregroundColor(Color.mainText)
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
        switch slot.lowercased() {
        case "breakfast": return (day.breakfasts as? Set<Meal>)?.sorted { ($0.name ?? "") < ($1.name ?? "") } ?? []
        case "lunch": return (day.lunches as? Set<Meal>)?.sorted { ($0.name ?? "") < ($1.name ?? "") } ?? []
        case "dinner": return (day.dinners as? Set<Meal>)?.sorted { ($0.name ?? "") < ($1.name ?? "") } ?? []
        case "other": return (day.others as? Set<Meal>)?.sorted { ($0.name ?? "") < ($1.name ?? "") } ?? []
        default: return []
        }
    }
} 
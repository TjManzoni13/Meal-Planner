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
    let onAdd: (Meal) -> Void
    let onRemove: (Meal) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Show all selected meals for the slot
            ForEach(currentMeals(), id: \.self) { meal in
                HStack {
                    Text(meal.name ?? "")
                        .font(.caption)
                    Spacer()
                    Button(action: {
                        onRemove(meal)
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            // Add meal menu
            Menu {
                ForEach(filteredMeals(), id: \.self) { meal in
                    Button(meal.name ?? "") {
                        onAdd(meal)
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "plus.circle")
                        .font(.caption)
                    Text("Add meal")
                        .font(.caption)
                }
                .foregroundColor(.blue)
                .padding(6)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(4)
            }
        }
    }

    private func filteredMeals() -> [Meal] {
        return meals.filter { meal in
            guard let tags = meal.tags?.lowercased() else { return false }
            return tags.contains(slot.lowercased()) || tags.contains("all")
        }
    }

    private func currentMeals() -> [Meal] {
        switch slot.lowercased() {
        case "breakfast": return (day.breakfasts as? Set<Meal>)?.sorted { ($0.name ?? "") < ($1.name ?? "") } ?? []
        case "lunch": return (day.lunches as? Set<Meal>)?.sorted { ($0.name ?? "") < ($1.name ?? "") } ?? []
        case "dinner": return (day.dinners as? Set<Meal>)?.sorted { ($0.name ?? "") < ($1.name ?? "") } ?? []
        case "other": return (day.others as? Set<Meal>)?.sorted { ($0.name ?? "") < ($1.name ?? "") } ?? []
        default: return []
        }
    }
}

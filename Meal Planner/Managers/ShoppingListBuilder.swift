//
//  ShoppingListBuilder.swift
//  Meal Planner
//
//  Created by Tj Manzoni on 10/07/2025.
//


import Foundation
import CoreData

struct ShoppingListItem: Hashable {
    let name: String
    let source: String // e.g. "Usual", "Meal: Pasta", or "Manual"
}

class ShoppingListBuilder: ObservableObject {
    @Published var items: [ShoppingListItem] = []
    @Published var tickedOff: Set<ShoppingListItem> = []

    func build(from weekPlan: WeekMealPlan?, household: Household?) {
        guard let weekPlan = weekPlan, let household = household else {
            self.items = []
            return
        }

        var result: [ShoppingListItem] = []

        // Add Usual Items
        if let usuals = household.usualItems as? Set<UsualItem> {
            for usual in usuals {
                result.append(ShoppingListItem(name: usual.name ?? "", source: "Usual"))
            }
        }

        // Add Meal Ingredients
        if let days = weekPlan.days as? Set<MealDay> {
            for day in days {
                for meal in [day.breakfast, day.lunch, day.dinner, day.other] {
                    guard let meal = meal, let mealName = meal.name else { continue }
                    if let ingredients = meal.ingredients as? Set<Ingredient> {
                        for ing in ingredients {
                            result.append(ShoppingListItem(name: ing.name ?? "", source: "Meal: \(mealName)"))
                        }
                    }
                }
            }
        }

        // Add Manual Ingredients
        if let manual = weekPlan.manualIngredients as? Set<Ingredient> {
            for ing in manual {
                result.append(ShoppingListItem(name: ing.name ?? "", source: "Manual"))
            }
        }

        self.items = result
    }

    func toggleItem(_ item: ShoppingListItem) {
        if tickedOff.contains(item) {
            tickedOff.remove(item)
        } else {
            tickedOff.insert(item)
        }
    }

    func isTicked(_ item: ShoppingListItem) -> Bool {
        return tickedOff.contains(item)
    }
}

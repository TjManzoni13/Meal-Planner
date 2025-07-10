//
//  ShoppingListBuilder.swift
//  Meal Planner
//
//  Created by Tj Manzoni on 10/07/2025.
//

import Foundation
import CoreData
import SwiftUI

struct ShoppingListItem: Hashable {
    let name: String
    let source: String // e.g. "Usual", "Meal: Pasta", or "Manual"
    let id = UUID() // Ensure uniqueness for Hashable
}

class ShoppingListBuilder: ObservableObject {
    @Published var everydayItems: [ShoppingListItem] = []
    @Published var mealItems: [ShoppingListItem] = []
    @Published var manualItems: [ShoppingListItem] = []
    @Published var tickedOff: Set<ShoppingListItem> = []
    
    private var duplicateColors: [String: Color] = [:]
    private let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]

    func build(from weekPlan: WeekMealPlan?, household: Household?) {
        guard let weekPlan = weekPlan, let household = household else {
            clearAllItems()
            return
        }


        
        // Clear previous items
        clearAllItems()
        
        // Build duplicate color mapping
        buildDuplicateColorMapping(from: weekPlan, household: household)

        // Add Everyday Items
        if let usuals = household.usualItems as? Set<UsualItem> {
            for usual in usuals {
                everydayItems.append(ShoppingListItem(name: usual.name ?? "", source: "Usual"))
            }
        }

        // Add Meal Ingredients
        if let days = weekPlan.days as? Set<MealDay> {
            print("Processing \(days.count) days for shopping list")
            for day in days {
                // Skip ingredients if day is marked as "already have"
                if day.alreadyHave {
                    print("Skipping day with alreadyHave = true: \(day.date?.description ?? "unknown")")
                    continue
                }
                
                print("Processing day: \(day.date?.description ?? "unknown") - alreadyHave: \(day.alreadyHave)")
                let meals = [day.breakfast, day.lunch, day.dinner, day.other]
                print("Day has \(meals.compactMap { $0 }.count) meals assigned")
                for meal in meals {
                    guard let meal = meal, let mealName = meal.name else { 
                        print("Skipping nil meal or meal without name")
                        continue 
                    }
                    print("Processing meal: \(mealName)")
                    if let ingredients = meal.ingredients as? Set<Ingredient> {
                        print("Adding \(ingredients.count) ingredients from meal: \(mealName)")
                        for ing in ingredients {
                            mealItems.append(ShoppingListItem(name: ing.name ?? "", source: "Meal: \(mealName)"))
                        }
                    } else {
                        print("No ingredients found for meal: \(mealName)")
                    }
                }
            }
        }

        // Add Manual Slot Ingredients
        if let slotIngredients = weekPlan.manualSlotIngredients as? Set<ManualSlotIngredient> {
            for ing in slotIngredients {
                if let name = ing.name {
                    // Check if this ingredient belongs to a day marked as "already have"
                    let shouldInclude = !isIngredientFromAlreadyHaveDay(ing, weekPlan: weekPlan)
                    if shouldInclude {
                        manualItems.append(ShoppingListItem(name: name, source: "Manual Slot"))
                    } else {
                        print("Excluding manual ingredient '\(name)' because day is marked as 'already have'")
                    }
                }
            }
        }

        // Add Manual Ingredients
        if let manual = weekPlan.manualIngredients as? Set<Ingredient> {
            for ing in manual {
                manualItems.append(ShoppingListItem(name: ing.name ?? "", source: "Manual"))
            }
        }
        
        print("Final shopping list counts - mealItems: \(mealItems.count), manualItems: \(manualItems.count)")
    }

    func addManualItem(_ name: String) {
        let item = ShoppingListItem(name: name, source: "Manual")
        manualItems.append(item)
        
        // Update duplicate colors if needed
        updateDuplicateColors()
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

    func isDuplicate(_ item: ShoppingListItem) -> Bool {
        let allItems = everydayItems + mealItems + manualItems
        let count = allItems.filter { $0.name.lowercased() == item.name.lowercased() }.count
        return count > 1
    }

    func duplicateColor(for item: ShoppingListItem) -> Color {
        let normalizedName = item.name.lowercased()
        return duplicateColors[normalizedName] ?? .clear
    }

    private func clearAllItems() {
        everydayItems = []
        mealItems = []
        manualItems = []
        tickedOff = []
        duplicateColors = [:]
    }

    private func buildDuplicateColorMapping(from weekPlan: WeekMealPlan?, household: Household?) {
        var allIngredients: [String] = []
        
        // Collect all ingredient names
        if let usuals = household?.usualItems as? Set<UsualItem> {
            allIngredients.append(contentsOf: usuals.compactMap { $0.name })
        }
        
        if let days = weekPlan?.days as? Set<MealDay> {
            for day in days {
                // Skip ingredients if day is marked as "already have"
                if day.alreadyHave { continue }
                
                for meal in [day.breakfast, day.lunch, day.dinner, day.other] {
                    if let ingredients = meal?.ingredients as? Set<Ingredient> {
                        allIngredients.append(contentsOf: ingredients.compactMap { $0.name })
                    }
                }
            }
        }
        
        if let manual = weekPlan?.manualIngredients as? Set<Ingredient> {
            allIngredients.append(contentsOf: manual.compactMap { $0.name })
        }
        
        // Find duplicates and assign colors
        let ingredientCounts = Dictionary(grouping: allIngredients, by: { $0.lowercased() })
            .filter { $0.value.count > 1 }
        
        var colorIndex = 0
        for (ingredientName, _) in ingredientCounts {
            duplicateColors[ingredientName] = colors[colorIndex % colors.count]
            colorIndex += 1
        }
    }

    private func updateDuplicateColors() {
        let allItems = everydayItems + mealItems + manualItems
        let ingredientCounts = Dictionary(grouping: allItems, by: { $0.name.lowercased() })
            .filter { $0.value.count > 1 }
        
        var colorIndex = 0
        for (ingredientName, _) in ingredientCounts {
            duplicateColors[ingredientName] = colors[colorIndex % colors.count]
            colorIndex += 1
        }
    }
    
    private func isIngredientFromAlreadyHaveDay(_ ingredient: ManualSlotIngredient, weekPlan: WeekMealPlan) -> Bool {
        guard let ingredientDate = ingredient.date else { return false }
        
        // Check if the ingredient's date corresponds to a day marked as "already have"
        if let days = weekPlan.days as? Set<MealDay> {
            for day in days {
                if let dayDate = day.date, Calendar.current.isDate(dayDate, inSameDayAs: ingredientDate) {
                    return day.alreadyHave
                }
            }
        }
        
        return false
    }
}

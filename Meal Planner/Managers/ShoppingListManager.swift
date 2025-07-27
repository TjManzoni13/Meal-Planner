//
//  ShoppingListManager.swift
//  Meal Planner
//
//  Created by Tj Manzoni on 10/07/2025.
//

import Foundation
import CoreData
import SwiftUI

/// Manages shopping list functionality including generation, persistence, and item management
class ShoppingListManager: ObservableObject {
    @Published var shoppingItems: [ShoppingListItem] = []
    @Published var tickedOffItems: [ShoppingListItem] = []
    
    private let context = CoreDataManager.shared.context
    
    // MARK: - Generate Shopping List
    
    /// Generates a new shopping list from all week plans (not just current week)
    /// This function is called manually when the user presses the "Generate Shopping List" button
    func generateShoppingList(for weekPlan: WeekMealPlan?, household: Household?) {
        guard let household = household else {
            clearGeneratedItems()
            return
        }
        
        // Clear existing generated items (but keep ticked off items)
        clearGeneratedItems()
        
        // Add Usual Items (always included)
        addUsualItems(from: household)
        
        // Get all relevant week plans (current week and future weeks, up to 4 weeks back)
        let allWeekPlans = getAllRelevantWeekPlans(for: household)
        
        // Add items from all week plans
        for weekPlan in allWeekPlans {
            addMealPlanItems(from: weekPlan)
        }
        
        // Save to Core Data (use the current week plan for storage)
        if let currentWeekPlan = weekPlan {
            saveShoppingList(to: currentWeekPlan)
            // Refresh arrays from Core Data to ensure tick/untick works
            loadShoppingList(from: currentWeekPlan)
        }
    }
    
    // MARK: - Load Shopping List
    
    /// Loads existing shopping list items from Core Data
    func loadShoppingList(from weekPlan: WeekMealPlan?) {
        guard let household = weekPlan?.household else {
            clearAllItems()
            return
        }
        
        // Get all relevant week plans and load items from all of them
        let allWeekPlans = getAllRelevantWeekPlans(for: household)
        
        let request: NSFetchRequest<ShoppingListItem> = ShoppingListItem.fetchRequest()
        request.predicate = NSPredicate(format: "weekPlan IN %@", allWeekPlans)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \ShoppingListItem.originDate, ascending: true),
            NSSortDescriptor(keyPath: \ShoppingListItem.name, ascending: true)
        ]
        
        do {
            let items = try context.fetch(request)
            shoppingItems = items.filter { !$0.isTicked }
            tickedOffItems = items.filter { $0.isTicked }
        } catch {
            print("Error loading shopping list: \(error)")
            clearAllItems()
        }
    }
    
    // MARK: - Item Management
    
    /// Toggles the ticked state of a shopping list item
    func toggleItem(_ item: ShoppingListItem) {
        print("Toggling item: \(item.name ?? "Unnamed") | objectID: \(item.objectID) | isTicked before: \(item.isTicked)")
        item.isTicked.toggle()
        print("isTicked after: \(item.isTicked)")
        CoreDataManager.shared.saveContext()
        if let weekPlan = item.weekPlan {
            print("Reloading shopping list for weekPlan objectID: \(weekPlan.objectID)")
            loadShoppingList(from: weekPlan)
            print("shoppingItems after reload: \(shoppingItems.map { $0.objectID })")
            print("tickedOffItems after reload: \(tickedOffItems.map { $0.objectID })")
        } else {
            print("Warning: item.weekPlan is nil!")
        }
    }
    
    /// Clears all ticked off items and marks corresponding meal slots as "already have"
    func clearTickedOffItems() {
        // Store the household before clearing items
        let household = tickedOffItems.first?.weekPlan?.household
        
        for item in tickedOffItems {
            // Only process items that originated from meals or manual slots
            if item.originType == "meal" || item.originType == "manual_slot" {
                markSlotAsAlreadyHave(for: item)
            }
            
            // Delete the item from Core Data
            context.delete(item)
        }
        
        tickedOffItems.removeAll()
        CoreDataManager.shared.saveContext()
        
        // Reload the shopping list to reflect changes
        if let household = household {
            let allWeekPlans = getAllRelevantWeekPlans(for: household)
            if let currentWeekPlan = allWeekPlans.first {
                loadShoppingList(from: currentWeekPlan)
            }
        }
    }
    
    /// Adds a manual item to the shopping list
    func addManualItem(_ name: String, to weekPlan: WeekMealPlan?) {
        guard let weekPlan = weekPlan, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let item = ShoppingListItem(context: context)
        item.id = UUID()
        item.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        item.originType = "manual"
        item.originDate = Date()
        item.isTicked = false
        item.weekPlan = weekPlan
        
        shoppingItems.append(item)
        CoreDataManager.shared.saveContext()
    }
    
    // MARK: - Private Helper Methods
    
    /// Adds usual items from household to shopping list
    private func addUsualItems(from household: Household) {
        if let usuals = household.usualItems as? Set<UsualItem> {
            for usual in usuals {
                let item = ShoppingListItem(context: context)
                item.id = UUID()
                item.name = usual.name ?? ""
                item.originType = "usual"
                item.originDate = Date()
                item.isTicked = false
                
                shoppingItems.append(item)
            }
        }
    }
    
    /// Adds items from meal plan to shopping list
    private func addMealPlanItems(from weekPlan: WeekMealPlan) {
        if let days = weekPlan.days as? Set<MealDay> {
            for day in days {
                let dayDate = day.date ?? Date()
                // For each slot, loop over all meals in the set
                let slotInfo: [(String, NSSet?, Bool)] = [
                    ("breakfast", day.breakfasts, day.alreadyHaveBreakfast),
                    ("lunch", day.lunches, day.alreadyHaveLunch),
                    ("dinner", day.dinners, day.alreadyHaveDinner),
                    ("other", day.others, day.alreadyHaveOther)
                ]
                for (slotName, mealSet, alreadyHave) in slotInfo {
                    if alreadyHave { 
                        continue 
                    }
                    let meals = mealSet?.allObjects as? [Meal] ?? []
                    for meal in meals {
                        if let ingredients = meal.ingredients as? Set<Ingredient> {
                            for ingredient in ingredients {
                                let item = ShoppingListItem(context: context)
                                item.id = UUID()
                                item.name = ingredient.name ?? ""
                                item.originType = "meal"
                                item.originMeal = meal.name
                                item.originSlot = slotName
                                item.originDate = dayDate
                                item.isTicked = false
                                shoppingItems.append(item)
                            }
                        }
                    }
                }
            }
        }
        // Add manual slot ingredients
        if let slotIngredients = weekPlan.manualSlotIngredients as? Set<ManualSlotIngredient> {
            for ingredient in slotIngredients {
                // Check if this ingredient belongs to a slot marked as "already have"
                if let ingredientDate = ingredient.date, let slot = ingredient.slot {
                    let shouldInclude = !isIngredientFromAlreadyHaveSlot(ingredientDate, slot: slot, weekPlan: weekPlan)
                    if shouldInclude {
                        let item = ShoppingListItem(context: context)
                        item.id = UUID()
                        item.name = ingredient.name ?? ""
                        item.originType = "manual_slot"
                        item.originSlot = slot
                        item.originDate = ingredientDate
                        item.isTicked = false
                        
                        shoppingItems.append(item)
                    } else {
                        continue
                    }
                }
            }
        }
    }
    
    /// Checks if an ingredient date and slot corresponds to a meal slot marked as "already have"
    private func isIngredientFromAlreadyHaveSlot(_ ingredientDate: Date, slot: String, weekPlan: WeekMealPlan) -> Bool {
        if let days = weekPlan.days as? Set<MealDay> {
            for day in days {
                if let dayDate = day.date, Calendar.current.isDate(dayDate, inSameDayAs: ingredientDate) {
                    switch slot.lowercased() {
                    case "breakfast": return day.alreadyHaveBreakfast
                    case "lunch": return day.alreadyHaveLunch
                    case "dinner": return day.alreadyHaveDinner
                    case "other": return day.alreadyHaveOther
                    default: return false
                    }
                }
            }
        }
        return false
    }
    
    /// Marks the corresponding meal slot as "already have" when clearing ticked items
    private func markSlotAsAlreadyHave(for item: ShoppingListItem) {
        guard let originDate = item.originDate,
              let originSlot = item.originSlot else { return }
        
        // Find the week plan that contains this date
        let weekStart = Calendar.current.startOfWeek(for: originDate)
        let request: NSFetchRequest<WeekMealPlan> = WeekMealPlan.fetchRequest()
        request.predicate = NSPredicate(format: "weekStart == %@", weekStart as NSDate)
        request.fetchLimit = 1
        
        do {
            if let weekPlan = try context.fetch(request).first,
               let days = weekPlan.days as? Set<MealDay> {
                for day in days {
                    if let dayDate = day.date, Calendar.current.isDate(dayDate, inSameDayAs: originDate) {
                        // If manual_slot, mark the slot as already have regardless of meal name
                        if item.originType == "manual_slot" {
                            switch originSlot.lowercased() {
                            case "breakfast": day.alreadyHaveBreakfast = true
                            case "lunch": day.alreadyHaveLunch = true
                            case "dinner": day.alreadyHaveDinner = true
                            case "other": day.alreadyHaveOther = true
                            default: break
                            }
                            continue
                        }
                        // Mark the specific slot as "already have" if any meal in the slot matches
                        switch originSlot.lowercased() {
                        case "breakfast":
                            if let meals = day.breakfasts as? Set<Meal>, meals.contains(where: { $0.name == item.originMeal }) {
                                day.alreadyHaveBreakfast = true
                            }
                        case "lunch":
                            if let meals = day.lunches as? Set<Meal>, meals.contains(where: { $0.name == item.originMeal }) {
                                day.alreadyHaveLunch = true
                            }
                        case "dinner":
                            if let meals = day.dinners as? Set<Meal>, meals.contains(where: { $0.name == item.originMeal }) {
                                day.alreadyHaveDinner = true
                            }
                        case "other":
                            if let meals = day.others as? Set<Meal>, meals.contains(where: { $0.name == item.originMeal }) {
                                day.alreadyHaveOther = true
                            }
                        default: break
                        }
                    }
                }
            }
        } catch {
            print("Error finding week plan for marking already have: \(error)")
        }
    }
    
    /// Saves shopping list items to Core Data
    private func saveShoppingList(to weekPlan: WeekMealPlan) {
        for item in shoppingItems {
            // Associate all items with the current week plan for storage
            // The originDate and originSlot will help identify which week/day they came from
            item.weekPlan = weekPlan
        }
        CoreDataManager.shared.saveContext()
    }
    
    /// Fetches all relevant week plans for the household (current week and future weeks, up to 4 weeks back)
    private func getAllRelevantWeekPlans(for household: Household) -> [WeekMealPlan] {
        let currentWeekStart = Calendar.current.startOfWeek(for: Date())
        let cutoffDate = Calendar.current.date(byAdding: .weekOfYear, value: -4, to: currentWeekStart) ?? currentWeekStart
        
        let request: NSFetchRequest<WeekMealPlan> = WeekMealPlan.fetchRequest()
        request.predicate = NSPredicate(format: "household == %@ AND weekStart >= %@", household, cutoffDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WeekMealPlan.weekStart, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching week plans for shopping list: \(error)")
            return []
        }
    }
    
    /// Clears generated items but keeps ticked off items and unticked manual items
    private func clearGeneratedItems() {
        // Remove items from Core Data that are not ticked off and not manual
        for item in shoppingItems {
            if !item.isTicked && item.originType != "manual" {
                context.delete(item)
            }
        }
        // Keep unticked manual items in shoppingItems, and move any ticked items to tickedOffItems
        let untickedManuals = shoppingItems.filter { $0.originType == "manual" && !$0.isTicked }
        let tickedManuals = shoppingItems.filter { $0.originType == "manual" && $0.isTicked }
        shoppingItems = untickedManuals
        for item in tickedManuals {
            if !tickedOffItems.contains(item) {
                tickedOffItems.append(item)
            }
        }
    }
    
    /// Clears all items
    private func clearAllItems() {
        shoppingItems.removeAll()
        tickedOffItems.removeAll()
    }
} 

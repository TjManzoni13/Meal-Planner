//
//  WeekPlanManager.swift
//  Meal Planner
//
//  Created by Tj Manzoni on 10/07/2025.
//

import Foundation
import CoreData

class WeekPlanManager: ObservableObject {
    @Published var weekPlan: WeekMealPlan?

    private let context = CoreDataManager.shared.context

    func fetchOrCreateWeek(for startDate: Date, household: Household) {
        let request: NSFetchRequest<WeekMealPlan> = WeekMealPlan.fetchRequest()
        request.predicate = NSPredicate(format: "household == %@ AND weekStart == %@", household, startDate as NSDate)
        request.fetchLimit = 1

        do {
            if let existing = try context.fetch(request).first {
                self.weekPlan = existing
            } else {
                let newPlan = WeekMealPlan(context: context)
                newPlan.id = UUID()
                newPlan.weekStart = startDate
                newPlan.household = household
                CoreDataManager.shared.saveContext()
                self.weekPlan = newPlan
            }
        } catch {
            print("Failed to fetch or create week plan: \(error)")
        }
    }

    func addMeal(_ meal: Meal, to day: MealDay, slot: String) {
        switch slot.lowercased() {
        case "breakfast":
            day.addToBreakfasts(meal)
        case "lunch":
            day.addToLunches(meal)
        case "dinner":
            day.addToDinners(meal)
        case "other":
            day.addToOthers(meal)
        default: break
        }
        CoreDataManager.shared.saveContext()
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }

    func removeMeal(_ meal: Meal, from day: MealDay, slot: String) {
        switch slot.lowercased() {
        case "breakfast":
            day.removeFromBreakfasts(meal)
        case "lunch":
            day.removeFromLunches(meal)
        case "dinner":
            day.removeFromDinners(meal)
        case "other":
            day.removeFromOthers(meal)
        default: break
        }
        CoreDataManager.shared.saveContext()
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }

    func clearAllMeals(from day: MealDay) {
        day.breakfasts = NSSet()
        day.lunches = NSSet()
        day.dinners = NSSet()
        day.others = NSSet()
        CoreDataManager.shared.saveContext()
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }

    func createDay(for date: Date) -> MealDay {
        let day = MealDay(context: context)
        day.id = UUID()
        day.date = date
        return day
    }

    func addManualIngredient(_ name: String) {
        guard let weekPlan = weekPlan else { return }

        let ingredient = Ingredient(context: context)
        ingredient.id = UUID()
        ingredient.name = name
        ingredient.fromManual = true
        ingredient.weekPlan = weekPlan

        CoreDataManager.shared.saveContext()
    }

    func addManualSlotIngredient(name: String, slot: String, date: Date) {
        guard let weekPlan = weekPlan else { return }
        let ingredient = ManualSlotIngredient(context: context)
        ingredient.id = UUID()
        ingredient.name = name
        ingredient.slot = slot
        ingredient.date = date
        ingredient.weekPlan = weekPlan
        CoreDataManager.shared.saveContext()
        
        // Trigger UI update immediately
        self.objectWillChange.send()
    }

    func fetchManualSlotIngredients(for slot: String, date: Date) -> [ManualSlotIngredient] {
        guard let weekPlan = weekPlan, let all = weekPlan.manualSlotIngredients as? Set<ManualSlotIngredient> else { return [] }
        return all.filter { $0.slot == slot && $0.date != nil && Calendar.current.isDate($0.date!, inSameDayAs: date) }
    }

    func deleteManualSlotIngredient(_ ingredient: ManualSlotIngredient) {
        CoreDataManager.shared.delete(ingredient)
        
        // Trigger UI update
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }

    func removeDay(_ day: MealDay) {
        CoreDataManager.shared.delete(day)
    }
    
    // MARK: - Already Have Methods
    
    /// Toggles the "already have" state for a specific meal slot
    func toggleAlreadyHave(for day: MealDay, slot: String) {
        let oldValue = getAlreadyHave(for: day, slot: slot)
        setAlreadyHave(!oldValue, for: day, slot: slot)
        
        print("Toggled alreadyHave for day \(day.date?.description ?? "unknown") slot \(slot) from \(oldValue) to \(!oldValue)")
        
        // Trigger UI update for both planner and shopping list
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    /// Gets the "already have" state for a specific meal slot
    func getAlreadyHave(for day: MealDay, slot: String) -> Bool {
        switch slot.lowercased() {
        case "breakfast": return day.alreadyHaveBreakfast
        case "lunch": return day.alreadyHaveLunch
        case "dinner": return day.alreadyHaveDinner
        case "other": return day.alreadyHaveOther
        default: return false
        }
    }
    
    /// Sets the "already have" state for a specific meal slot
    func setAlreadyHave(_ value: Bool, for day: MealDay, slot: String) {
        switch slot.lowercased() {
        case "breakfast": day.alreadyHaveBreakfast = value
        case "lunch": day.alreadyHaveLunch = value
        case "dinner": day.alreadyHaveDinner = value
        case "other": day.alreadyHaveOther = value
        default: break
        }
        CoreDataManager.shared.saveContext()
    }
    
    /// Checks if a day has any meal slots marked as "already have"
    func hasAnyAlreadyHave(for day: MealDay) -> Bool {
        return day.alreadyHaveBreakfast || day.alreadyHaveLunch || day.alreadyHaveDinner || day.alreadyHaveOther
    }
    
    // Clean up old planner data (older than 4 weeks from current week)
    func cleanupOldPlannerData() {
        let currentWeekStart = Calendar.current.startOfWeek(for: Date())
        let cutoffDate = Calendar.current.date(byAdding: .weekOfYear, value: -4, to: currentWeekStart) ?? currentWeekStart
        
        // Delete old WeekMealPlans
        let weekPlanRequest: NSFetchRequest<WeekMealPlan> = WeekMealPlan.fetchRequest()
        weekPlanRequest.predicate = NSPredicate(format: "weekStart < %@", cutoffDate as NSDate)
        
        do {
            let oldWeekPlans = try context.fetch(weekPlanRequest)
            for weekPlan in oldWeekPlans {
                CoreDataManager.shared.delete(weekPlan)
            }
            
            // Also clean up any orphaned ManualSlotIngredients that might not be caught by cascade delete
            let manualIngredientRequest: NSFetchRequest<ManualSlotIngredient> = ManualSlotIngredient.fetchRequest()
            manualIngredientRequest.predicate = NSPredicate(format: "date < %@", cutoffDate as NSDate)
            
            let oldManualIngredients = try context.fetch(manualIngredientRequest)
            for ingredient in oldManualIngredients {
                CoreDataManager.shared.delete(ingredient)
            }
            
            // Save the context after cleanup
            CoreDataManager.shared.saveContext()
            
            print("Cleaned up \(oldWeekPlans.count) old week plans and \(oldManualIngredients.count) old manual ingredients")
        } catch {
            print("Failed to cleanup old planner data: \(error)")
        }
    }
}

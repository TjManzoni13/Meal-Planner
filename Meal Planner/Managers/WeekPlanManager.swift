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
        case "breakfast": day.breakfast = meal
        case "lunch": day.lunch = meal
        case "dinner": day.dinner = meal
        case "other": day.other = meal
        default: break
        }
        CoreDataManager.shared.saveContext()
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

    func removeDay(_ day: MealDay) {
        CoreDataManager.shared.delete(day)
    }
}

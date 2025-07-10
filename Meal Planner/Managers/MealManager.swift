//
//  MealManager.swift
//  Meal Planner
//
//  Created by Tj Manzoni on 10/07/2025.
//

import Foundation
import CoreData

class MealManager: ObservableObject {
    @Published var meals: [Meal] = []
    
    private let context = CoreDataManager.shared.context

    func fetchMeals(for household: Household?) {
        guard let household = household else {
            self.meals = []
            return
        }
        let request: NSFetchRequest<Meal> = Meal.fetchRequest()
        request.predicate = NSPredicate(format: "household == %@", household)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Meal.name, ascending: true)]

        do {
            self.meals = try context.fetch(request)
        } catch {
            print("Error fetching meals: \(error)")
            self.meals = []
        }
    }

    func addMeal(name: String, tags: [String], recipe: String?, ingredients: [String], to household: Household) {
        let meal = Meal(context: context)
        meal.id = UUID()
        meal.name = name
        meal.tags = tags.joined(separator: ",")
        meal.recipe = recipe
        meal.household = household

        for ingredientName in ingredients {
            let ingredient = Ingredient(context: context)
            ingredient.id = UUID()
            ingredient.name = ingredientName
            ingredient.fromManual = false
            ingredient.meal = meal
        }

        CoreDataManager.shared.saveContext()
        fetchMeals(for: household)
    }

    func deleteMeal(_ meal: Meal, from household: Household) {
        CoreDataManager.shared.delete(meal)
        fetchMeals(for: household)
    }

    func meals(forTag tag: String) -> [Meal] {
        return meals.filter { $0.tags.lowercased().contains(tag.lowercased()) || $0.tags.lowercased().contains("all") }
    }
}

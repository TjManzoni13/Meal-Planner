import SwiftUI

struct MealsAndUsualsView: View {
    @StateObject private var householdManager = HouseholdManager()
    @StateObject private var mealManager = MealManager()

    @State private var newUsualItem = ""
    @State private var newMealName = ""
    @State private var newMealTags = ""
    @State private var newMealIngredients = ""
    @State private var newMealRecipe = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Usual Items")) {
                    if let usuals = householdManager.household?.usualItems as? Set<UsualItem> {
                        ForEach(Array(usuals), id: \.self) { item in
                            Text(item.name ?? "")
                        }
                        .onDelete { indexSet in
                            if let index = indexSet.first {
                                let item = Array(usuals)[index]
                                CoreDataManager.shared.delete(item)
                            }
                        }
                    }

                    HStack {
                        TextField("Add item", text: $newUsualItem)
                        Button("Add") {
                            addUsualItem()
                        }
                    }
                }

                Section(header: Text("Create Meal")) {
                    TextField("Meal Name", text: $newMealName)
                    TextField("Tags (comma separated)", text: $newMealTags)
                    TextField("Ingredients (comma separated)", text: $newMealIngredients)
                    TextField("Recipe (optional)", text: $newMealRecipe)

                    Button("Save Meal") {
                        saveMeal()
                    }
                }

                Section(header: Text("Your Meals")) {
                    ForEach(mealManager.meals, id: \.self) { meal in
                        VStack(alignment: .leading) {
                            Text(meal.name ?? "")
                                .font(.headline)
                            Text("Tags: \(meal.tags ?? "")")
                                .font(.caption)
                            if let ingredients = meal.ingredients as? Set<Ingredient> {
                                Text("Ingredients: \(ingredients.map { $0.name ?? "" }.joined(separator: ", "))")
                                    .font(.caption2)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        if let index = indexSet.first {
                            let meal = mealManager.meals[index]
                            if let household = householdManager.household {
                                mealManager.deleteMeal(meal, from: household)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Meals")
            .onAppear {
                householdManager.loadOrCreateHousehold()
            }
            .onChange(of: householdManager.household) { _, household in
                if let household = household {
                    mealManager.fetchMeals(for: household)
                }
            }
        }
    }

    private func addUsualItem() {
        guard let household = householdManager.household, !newUsualItem.isEmpty else { return }
        let item = UsualItem(context: CoreDataManager.shared.context)
        item.id = UUID()
        item.name = newUsualItem
        item.household = household
        CoreDataManager.shared.saveContext()
        newUsualItem = ""
    }

    private func saveMeal() {
        guard let household = householdManager.household, !newMealName.isEmpty else { return }
        let tagList = newMealTags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        let ingredientList = newMealIngredients.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        mealManager.addMeal(name: newMealName, tags: tagList, recipe: newMealRecipe, ingredients: ingredientList, to: household)

        newMealName = ""
        newMealTags = ""
        newMealIngredients = ""
        newMealRecipe = ""
    }
}

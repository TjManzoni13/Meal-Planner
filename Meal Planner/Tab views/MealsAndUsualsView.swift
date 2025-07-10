import SwiftUI

struct MealsAndUsualsView: View {
    @StateObject private var householdManager = HouseholdManager()
    @StateObject private var mealManager = MealManager()

    @State private var newUsualItem = ""
    @State private var newMealName = ""
    @State private var newMealTags = ""
    @State private var newMealIngredients = ""
    @State private var newMealRecipe = ""
    @State private var selectedTagFilter = "All"
    @State private var showingMealDetail = false
    @State private var selectedMeal: Meal?

    let availableTags = ["All", "Breakfast", "Lunch", "Dinner", "Multiple"]

    var body: some View {
        NavigationView {
            VStack {
                // Tag filter picker
                Picker("Filter by tag", selection: $selectedTagFilter) {
                    ForEach(availableTags, id: \.self) { tag in
                        Text(tag).tag(tag)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)

                List {
                    // Usual Items Section
                    Section(header: Text("Usual Items").font(.headline)) {
                        if let usuals = householdManager.household?.usualItems as? Set<UsualItem> {
                            ForEach(Array(usuals), id: \.self) { item in
                                HStack {
                                    Image(systemName: "list.bullet")
                                        .foregroundColor(.blue)
                                        .font(.caption)
                                    
                                    Text(item.name ?? "")
                                    
                                    Spacer()
                                }
                            }
                            .onDelete { indexSet in
                                if let index = indexSet.first {
                                    let item = Array(usuals)[index]
                                    CoreDataManager.shared.delete(item)
                                }
                            }
                        }

                        HStack {
                            TextField("Add usual item", text: $newUsualItem)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Button("Add") {
                                addUsualItem()
                            }
                            .disabled(newUsualItem.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .buttonStyle(.borderedProminent)
                        }
                    }

                    // Create Meal Section
                    Section(header: Text("Create New Meal").font(.headline)) {
                        VStack(alignment: .leading, spacing: 12) {
                            TextField("Meal Name", text: $newMealName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            TextField("Tags (comma separated: Breakfast, Lunch, Dinner, Multiple)", text: $newMealTags)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            TextField("Ingredients (comma separated)", text: $newMealIngredients)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Recipe (optional)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                TextEditor(text: $newMealRecipe)
                                    .frame(minHeight: 80)
                                    .padding(4)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                            }

                            Button("Save Meal") {
                                saveMeal()
                            }
                            .disabled(newMealName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .buttonStyle(.borderedProminent)
                            .frame(maxWidth: .infinity)
                        }
                    }

                    // Your Meals Section
                    Section(header: Text("Your Meals").font(.headline)) {
                        ForEach(filteredMeals, id: \.self) { meal in
                            MealRowView(meal: meal) {
                                selectedMeal = meal
                                showingMealDetail = true
                            }
                        }
                        .onDelete { indexSet in
                            if let index = indexSet.first {
                                let meal = filteredMeals[index]
                                if let household = householdManager.household {
                                    mealManager.deleteMeal(meal, from: household)
                                }
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("Meals & Usuals")
            .sheet(isPresented: $showingMealDetail) {
                if let meal = selectedMeal {
                    MealDetailView(meal: meal)
                }
            }
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

    private var filteredMeals: [Meal] {
        if selectedTagFilter == "All" {
            return mealManager.meals
        } else {
            return mealManager.meals.filter { meal in
                let tags = meal.tags?.lowercased() ?? ""
                return tags.contains(selectedTagFilter.lowercased())
            }
        }
    }

    private func addUsualItem() {
        guard let household = householdManager.household, !newUsualItem.isEmpty else { return }
        let item = UsualItem(context: CoreDataManager.shared.context)
        item.id = UUID()
        item.name = newUsualItem.trimmingCharacters(in: .whitespacesAndNewlines)
        item.household = household
        CoreDataManager.shared.saveContext()
        newUsualItem = ""
    }

    private func saveMeal() {
        guard let household = householdManager.household, !newMealName.isEmpty else { return }
        let tagList = newMealTags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        let ingredientList = newMealIngredients.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        mealManager.addMeal(name: newMealName.trimmingCharacters(in: .whitespacesAndNewlines), tags: tagList, recipe: newMealRecipe.trimmingCharacters(in: .whitespacesAndNewlines), ingredients: ingredientList, to: household)

        newMealName = ""
        newMealTags = ""
        newMealIngredients = ""
        newMealRecipe = ""
    }
}

// MARK: - Meal Row View
struct MealRowView: View {
    let meal: Meal
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(meal.name ?? "")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    if let tags = meal.tags, !tags.isEmpty {
                        Text("Tags: \(tags)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
            
            if let ingredients = meal.ingredients as? Set<Ingredient>, !ingredients.isEmpty {
                Text("Ingredients: \(ingredients.map { $0.name ?? "" }.joined(separator: ", "))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Meal Detail View
struct MealDetailView: View {
    let meal: Meal
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Meal name and tags
                    VStack(alignment: .leading, spacing: 8) {
                        Text(meal.name ?? "")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        if let tags = meal.tags, !tags.isEmpty {
                            Text("Tags: \(tags)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Ingredients
                    if let ingredients = meal.ingredients as? Set<Ingredient>, !ingredients.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Ingredients")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            ForEach(Array(ingredients), id: \.self) { ingredient in
                                HStack {
                                    Image(systemName: "circle.fill")
                                        .foregroundColor(.blue)
                                        .font(.caption)
                                    
                                    Text(ingredient.name ?? "")
                                    
                                    Spacer()
                                }
                            }
                        }
                    }
                    
                    // Recipe
                    if let recipe = meal.recipe, !recipe.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Recipe")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text(recipe)
                                .font(.body)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Meal Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

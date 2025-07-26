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
    
    // Focus states for keyboard management
    @FocusState private var isUsualItemFocused: Bool
    @FocusState private var isMealNameFocused: Bool
    @FocusState private var isMealTagsFocused: Bool
    @FocusState private var isMealIngredientsFocused: Bool
    @FocusState private var isMealRecipeFocused: Bool

    let availableTags = ["All", "Breakfast", "Lunch", "Dinner", "Multiple"]

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea() // App-wide background
                VStack {
                    // Tag filter picker
                    Picker("Filter by tag", selection: $selectedTagFilter) {
                        ForEach(availableTags, id: \.self) { tag in
                            Text(tag)
                                .foregroundColor(.black)
                                .tag(tag)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)

                    List {
                        // Usual Items Section
                        Section(header: Text("Usual Items").font(.headline).foregroundColor(.black)) {
                            if let usuals = householdManager.household?.usualItems as? Set<UsualItem> {
                                ForEach(Array(usuals), id: \.self) { item in
                                    HStack {
                                        Image(systemName: "list.bullet")
                                            .foregroundColor(.blue)
                                            .font(.caption)
                                        
                                        Text(item.name ?? "")
                                            .foregroundColor(.black)

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
                                    .focused($isUsualItemFocused)
                                    .submitLabel(.done)
                                    .foregroundColor(.black)
                                    .background(Color.accent)
                                    .cornerRadius(8)
                                    .onSubmit {
                                        addUsualItem()
                                    }
                                Button("Add") {
                                    addUsualItem()
                }
                                .disabled(newUsualItem.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                .buttonStyle(.borderedProminent)
                                .tint(Color.buttonBackground)
                                .foregroundColor(.black)
                            }
                            .listRowBackground(Color.buttonBackground)
                        }

                        // Create Meal Section
                        Section(header: Text("Create New Meal").font(.headline).foregroundColor(.black)) {
                            VStack(alignment: .leading, spacing: 12) {
                                TextField("Meal Name", text: $newMealName)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .focused($isMealNameFocused)
                                    .submitLabel(.next)
                                    .foregroundColor(.black)
                                    .background(Color.accent)
                                    .cornerRadius(8)
                                    .onSubmit {
                                        isMealTagsFocused = true
            }

                                TextField("Tags (comma separated: Breakfast, Lunch, Dinner, Multiple)", text: $newMealTags)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .focused($isMealTagsFocused)
                                    .submitLabel(.next)
                                    .foregroundColor(.black)
                                    .background(Color.accent)
                                    .cornerRadius(8)
                                    .onSubmit {
                                        isMealIngredientsFocused = true
    }

                                TextField("Ingredients (comma separated)", text: $newMealIngredients)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .focused($isMealIngredientsFocused)
                                    .submitLabel(.next)
                        .foregroundColor(.black)
                                    .background(Color.accent)
                                    .cornerRadius(8)
                                    .onSubmit {
                                        isMealRecipeFocused = true
                                    }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Recipe (optional)")
                            .font(.caption)
                                        .foregroundColor(.black)

                                    TextEditor(text: $newMealRecipe)
                                        .padding(4)
                                        .frame(minHeight: 80)
                                        .background(Color.accent)
                                        .cornerRadius(8)
                    .foregroundColor(.black)
                                        .focused($isMealRecipeFocused)
            }

                                Button("Save Meal") {
                                    saveMeal()
                                }
                                .disabled(newMealName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                .buttonStyle(.borderedProminent)
                                .tint(Color.buttonBackground)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                            }
                            .listRowBackground(Color.buttonBackground)
                        }

                        // Your Meals Section
                        Section(header: Text("Your Meals").font(.headline).foregroundColor(.black)) {
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
                        .listRowBackground(Color.buttonBackground)
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("Meals & Usuals")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingMealDetail) {
                if let meal = selectedMeal {
                    MealDetailView(meal: meal)
                    }
                }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        dismissAllKeyboards()
            }
                    .foregroundColor(.black)
    }
}
            .onAppear {
                householdManager.loadOrCreateHousehold()
            }
            .onChange(of: householdManager.household) { oldValue, newValue in
                if let household = newValue {
                    mealManager.fetchMeals(for: household)
                }
            }
            // Tap gesture to dismiss keyboard when tapping outside
            .onTapGesture {
                dismissAllKeyboards()
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
    
    private func dismissAllKeyboards() {
        isUsualItemFocused = false
        isMealNameFocused = false
        isMealTagsFocused = false
        isMealIngredientsFocused = false
        isMealRecipeFocused = false
    }

    private func addUsualItem() {
        let trimmed = newUsualItem.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let household = householdManager.household, !trimmed.isEmpty else { print("addUsualItem: empty or no household"); return }
        print("addUsualItem: Adding usual item '", trimmed, "'")
        let item = UsualItem(context: CoreDataManager.shared.context)
        item.id = UUID()
        item.name = trimmed
        item.household = household
        CoreDataManager.shared.saveContext()
        newUsualItem = ""
        isUsualItemFocused = false
    }

    private func saveMeal() {
        print("saveMeal: Called")
        guard let household = householdManager.household, !newMealName.isEmpty else { print("saveMeal: empty or no household"); return }
        let tagList = newMealTags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        let ingredientList = newMealIngredients.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        print("saveMeal: Adding meal '", newMealName, "' with tags '", tagList, "' and ingredients '", ingredientList, "'")
        mealManager.addMeal(name: newMealName.trimmingCharacters(in: .whitespacesAndNewlines), tags: tagList, recipe: newMealRecipe.trimmingCharacters(in: .whitespacesAndNewlines), ingredients: ingredientList, to: household)

        newMealName = ""
        newMealTags = ""
        newMealIngredients = ""
        newMealRecipe = ""
        dismissAllKeyboards()
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
                        .foregroundColor(.black)
                            
                    if let tags = meal.tags, !tags.isEmpty {
                        Text("Tags: \(tags)")
                            .font(.caption)
                            .foregroundColor(.black)
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
                    .foregroundColor(.black)
                    .lineLimit(2)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            print("MealRowView: Tapped meal '", meal.name ?? "", "'")
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
                            .foregroundColor(.black)

                        if let tags = meal.tags, !tags.isEmpty {
                            Text("Tags: \(tags)")
                                .font(.subheadline)
                                .foregroundColor(.black)
                    }
                }

                    // Ingredients
                    if let ingredients = meal.ingredients as? Set<Ingredient>, !ingredients.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Ingredients")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.black)

                            ForEach(Array(ingredients), id: \.self) { ingredient in
                                HStack {
                                    Image(systemName: "circle.fill")
                                        .foregroundColor(.blue)
                                        .font(.caption)
                                    
                                    Text(ingredient.name ?? "")
                                        .foregroundColor(.black)

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
                                .foregroundColor(.black)

                            Text(recipe)
                                .font(.body)
                                .foregroundColor(.black)
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

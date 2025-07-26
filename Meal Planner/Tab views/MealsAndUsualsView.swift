import SwiftUI

struct MealsView: View {
    @StateObject private var householdManager = HouseholdManager()
    @StateObject private var mealManager = MealManager()

    @State private var newMealName = ""
    @State private var selectedTags: Set<String> = []
    @State private var newMealIngredients = ""
    @State private var newMealRecipe = ""
    @State private var selectedTagFilter = "All"
    @State private var selectedMeal: Meal?
    
    // Focus states for keyboard management
    @FocusState private var isMealNameFocused: Bool
    @FocusState private var isMealTagsFocused: Bool
    @FocusState private var isMealIngredientsFocused: Bool
    @FocusState private var isMealRecipeFocused: Bool

    let availableTags = ["All", "Breakfast", "Lunch", "Dinner"]

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea() // App-wide background
                VStack {
                    // Tag filter picker
                    HStack(spacing: 0) {
                        ForEach(availableTags, id: \.self) { tag in
                            Button(action: {
                                selectedTagFilter = tag
                            }) {
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedTagFilter == tag ? Color.buttonBackground : Color.clear)
                                    .foregroundColor(selectedTagFilter == tag ? .white : .black)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)

                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // Create Meal Section
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Create New Meal")
                                    .font(.headline)
                                    .foregroundColor(.black)
                                    .padding(.horizontal)
                                
                                VStack(alignment: .leading, spacing: 12) {
                                    TextField("Meal Name", text: $newMealName)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color.accent)
                                        .cornerRadius(8)
                                        .focused($isMealNameFocused)
                                        .submitLabel(.next)
                                        .onSubmit {
                                            isMealTagsFocused = true
                                        }

                                    HStack(spacing: 8) {
                                        ForEach(["Breakfast", "Lunch", "Dinner"], id: \.self) { tag in
                                            Button(action: {
                                                if selectedTags.contains(tag) {
                                                    selectedTags.remove(tag)
                                                } else {
                                                    selectedTags.insert(tag)
                                                }
                                            }) {
                                                HStack {
                                                    Text(tag)
                                                        .font(.caption)
                                                    if selectedTags.contains(tag) {
                                                        Image(systemName: "checkmark")
                                                            .font(.caption)
                                                            .foregroundColor(Color.buttonBackground)
                                                    }
                                                }
                                                .frame(maxWidth: .infinity)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(Color.accent)
                                                .foregroundColor(.black)
                                                .cornerRadius(8)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }

                                    TextField("Ingredients (comma separated)", text: $newMealIngredients)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color.accent)
                                        .cornerRadius(8)
                                        .focused($isMealIngredientsFocused)
                                        .submitLabel(.next)
                                        .onSubmit {
                                            isMealRecipeFocused = true
                                        }

                                    ZStack {
                                        Color.accent
                                            .cornerRadius(8)
                                        TextEditor(text: $newMealRecipe)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .frame(minHeight: 80)
                                            .background(Color.clear)
                                            .foregroundColor(.black)
                                            .focused($isMealRecipeFocused)
                                            .scrollContentBackground(.hidden)
                                            .overlay(
                                                Group {
                                                    if newMealRecipe.isEmpty {
                                                        Text("Recipe (optional)")
                                                            .foregroundColor(.gray)
                                                            .padding(.horizontal, 16)
                                                            .padding(.vertical, 12)
                                                            .allowsHitTesting(false)
                                                    }
                                                },
                                                alignment: .topLeading
                                            )
                                    }
                                    .frame(minHeight: 80)

                                    Button("Save Meal") {
                                        saveMeal()
                                    }
                                    .disabled(newMealName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.accent)
                                    .foregroundColor(.black)
                                    .cornerRadius(8)
                                }
                                .padding()
                                .background(Color.buttonBackground)
                                .cornerRadius(8)
                                .padding(.horizontal)
                            }

                            // Your Meals Section
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Your Meals")
                                    .font(.headline)
                                    .foregroundColor(.black)
                                    .padding(.horizontal)
                                
                                ForEach(filteredMeals, id: \.objectID) { meal in
                                    MealRowView(meal: meal) {
                                        selectedMeal = nil
                                        // Force resolve Core Data faulting to prevent blank sheet
                                        _ = meal.name
                                        _ = meal.tags
                                        _ = (meal.ingredients as? Set<Ingredient>)?.map { $0.name }
                                        
                                        selectedMeal = meal
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 4)
                                    .background(Color.buttonBackground)
                                    .cornerRadius(8)
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Meals")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedMeal) { meal in
                MealDetailView(meal: meal)
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
            }.sorted { ($0.name ?? "") < ($1.name ?? "") }
        }
    }
    
    private func dismissAllKeyboards() {
        isMealNameFocused = false
        isMealTagsFocused = false
        isMealIngredientsFocused = false
        isMealRecipeFocused = false
    }



    private func saveMeal() {
        print("saveMeal: Called")
        guard let household = householdManager.household, !newMealName.isEmpty else { print("saveMeal: empty or no household"); return }
        let tagList = Array(selectedTags)
        let ingredientList = newMealIngredients.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        print("saveMeal: Adding meal '", newMealName, "' with tags '", tagList, "' and ingredients '", ingredientList, "'")
        mealManager.addMeal(name: newMealName.trimmingCharacters(in: .whitespacesAndNewlines), tags: tagList, recipe: newMealRecipe.trimmingCharacters(in: .whitespacesAndNewlines), ingredients: ingredientList, to: household)

        newMealName = ""
        selectedTags.removeAll()
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
                Text("Ingredients: \(ingredients.map { $0.name ?? "" }.sorted().joined(separator: ", "))")
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
    @StateObject private var mealManager = MealManager()
    
    @State private var editedName: String = ""
    @State private var editedSelectedTags: Set<String> = []
    @State private var editedIngredients: String = ""
    @State private var editedRecipe: String = ""
    @State private var isEditing = false
    
    // Focus states for keyboard management
    @FocusState private var isNameFocused: Bool
    @FocusState private var isIngredientsFocused: Bool
    @FocusState private var isRecipeFocused: Bool

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if isEditing {
                            // Edit mode
                            VStack {
                                VStack(alignment: .leading, spacing: 12) {
                                Text("Meal Name")
                                    .font(.headline)
                                    .foregroundColor(.black)
                                
                                TextField("Meal Name", text: $editedName)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.accent)
                                    .cornerRadius(8)
                                    .foregroundColor(.black)
                                    .focused($isNameFocused)
                                
                                Text("Tags")
                                    .font(.headline)
                                    .foregroundColor(.black)
                                
                                HStack(spacing: 8) {
                                    ForEach(["Breakfast", "Lunch", "Dinner"], id: \.self) { tag in
                                        Button(action: {
                                            if editedSelectedTags.contains(tag) {
                                                editedSelectedTags.remove(tag)
                                            } else {
                                                editedSelectedTags.insert(tag)
                                            }
                                        }) {
                                            Text(tag)
                                                .font(.caption)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(editedSelectedTags.contains(tag) ? Color.buttonBackground : Color.accent)
                                                .foregroundColor(editedSelectedTags.contains(tag) ? .white : .black)
                                                .cornerRadius(8)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                
                                Text("Ingredients")
                                    .font(.headline)
                                    .foregroundColor(.black)
                                
                                TextField("Ingredients (comma separated)", text: $editedIngredients)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.accent)
                                    .cornerRadius(8)
                                    .foregroundColor(.black)
                                    .focused($isIngredientsFocused)
                                
                                ZStack {
                                    Color.accent
                                        .cornerRadius(8)
                                    TextEditor(text: $editedRecipe)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .frame(minHeight: 80)
                                        .background(Color.clear)
                                        .foregroundColor(.black)
                                        .focused($isRecipeFocused)
                                        .scrollContentBackground(.hidden)
                                        .overlay(
                                            Group {
                                                if editedRecipe.isEmpty {
                                                    Text("Recipe (optional)")
                                                        .foregroundColor(.gray)
                                                        .padding(.horizontal, 16)
                                                        .padding(.vertical, 12)
                                                        .allowsHitTesting(false)
                                                }
                                            },
                                            alignment: .topLeading
                                        )
                                }
                                .frame(minHeight: 80)
                                
                                HStack {
                                    Button("Cancel") {
                                        isEditing = false
                                        loadMealData()
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.gray)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                                    
                                    Button("Save") {
                                        saveChanges()
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.buttonBackground)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                                }
                            }
                            
                            Spacer()
                            
                            // Delete Button - pinned to bottom
                            Button(action: {
                                deleteMeal()
                            }) {
                                HStack {
                                    Image(systemName: "trash")
                                        .foregroundColor(.white)
                                    Text("Delete Meal")
                                        .foregroundColor(.white)
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.buttonBackground)
                                .cornerRadius(8)
                            }
                        }
                        } else {
                            // View mode
                            VStack(alignment: .leading, spacing: 16) {
                                Text(meal.name ?? "Unnamed Meal")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.black)

                                if let tags = meal.tags, !tags.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Meals:")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.black)
                                        
                                        ForEach(tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }, id: \.self) { tag in
                                            HStack {
                                                Image(systemName: "circle.fill")
                                                    .foregroundColor(Color.accent)
                                                    .font(.caption)
                                                
                                                Text(tag)
                                                    .foregroundColor(.black)
                                                
                                                Spacer()
                                            }
                                        }
                                    }
                                } else {
                                    Text("No meals assigned")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }

                            // Ingredients
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Ingredients")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.black)

                                if let ingredients = meal.ingredients as? Set<Ingredient>, !ingredients.isEmpty {
                                    ForEach(Array(ingredients).sorted { ($0.name ?? "") < ($1.name ?? "") }, id: \.self) { ingredient in
                                        HStack {
                                            Image(systemName: "circle.fill")
                                                .foregroundColor(Color.accent)
                                                .font(.caption)
                                            
                                            Text(ingredient.name ?? "")
                                                .foregroundColor(.black)

                                            Spacer()
                                        }
                                    }
                                } else {
                                    Text("No ingredients")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }

                            // Recipe
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Recipe")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.black)

                                if let recipe = meal.recipe, !recipe.isEmpty {
                                    Text(recipe)
                                        .font(.body)
                                        .foregroundColor(.black)
                                } else {
                                    Text("No recipe")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle(isEditing ? "Edit Meal" : "Meal Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !isEditing {
                        Button("Edit") {
                            isEditing = true
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(isEditing ? "Cancel" : "Done") {
                        if isEditing {
                            isEditing = false
                            loadMealData()
                        } else {
                            dismiss()
                        }
                    }
                }
            }
            .onAppear {
                print("MealDetailView: Loading meal '\(meal.name ?? "Unknown")'")
                loadMealData()
            }
        }
    }
    
    private func loadMealData() {
        editedName = meal.name ?? ""
        editedSelectedTags = Set((meal.tags ?? "").split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) })
        editedIngredients = (meal.ingredients as? Set<Ingredient>)?.map { $0.name ?? "" }.sorted().joined(separator: ", ") ?? ""
        editedRecipe = meal.recipe ?? ""
    }
    
    private func saveChanges() {
        // Delete old ingredients
        if let ingredients = meal.ingredients as? Set<Ingredient> {
            for ingredient in ingredients {
                CoreDataManager.shared.delete(ingredient)
            }
        }
        
        // Update meal
        meal.name = editedName
        meal.tags = Array(editedSelectedTags).joined(separator: ", ")
        meal.recipe = editedRecipe
        
        // Add new ingredients
        let ingredientNames = editedIngredients.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        for ingredientName in ingredientNames {
            if !ingredientName.isEmpty {
                let ingredient = Ingredient(context: CoreDataManager.shared.context)
                ingredient.id = UUID()
                ingredient.name = ingredientName
                ingredient.fromManual = false
                ingredient.meal = meal
            }
        }
        
        CoreDataManager.shared.saveContext()
        isEditing = false
    }
    
    private func deleteMeal() {
        // Delete the meal from Core Data
        CoreDataManager.shared.delete(meal)
        CoreDataManager.shared.saveContext()
        
        // Dismiss the detail view
        dismiss()
    }
}



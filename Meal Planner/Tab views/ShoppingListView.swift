import SwiftUI

struct ShoppingListView: View {
    @StateObject private var householdManager = HouseholdManager()
    @StateObject private var weekPlanManager = WeekPlanManager()
    @StateObject private var shoppingListManager = ShoppingListManager()

    @State private var newManualItem = ""
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea() // App-wide background
                VStack {
                    // Generate Shopping List Button
                    Button(action: {
                        generateShoppingList()
                    }) {
                        HStack {
                            Image(systemName: "cart.badge.plus")
                                .foregroundColor(Color.mainText)
                            Text("Generate Shopping List")
                                .fontWeight(.medium)
                                .foregroundColor(Color.mainText)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.buttonBackground)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.accent, lineWidth: 2) // Accent border
                        )
                    }
                    .padding(.horizontal)
                    .padding(.top)

                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            // Usual Items Section
                            let usualItems = shoppingListManager.shoppingItems
                                .filter { $0.originType == "usual" }
                            let groupedUsualItems = groupItems(usualItems)
                            if !groupedUsualItems.isEmpty {
                                Text("Usual Items").font(.headline).padding([.leading, .top])
                                ForEach(groupedUsualItems, id: \.key) { group in
                                    ShoppingListGroupedRow(
                                        name: group.key,
                                        items: group.value,
                                        onToggle: {
                                            toggleAll(items: group.value)
                                        }
                                    )
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                    Divider()
                                }
                            }

                            // Generated Items Section
                            let generatedItems = shoppingListManager.shoppingItems
                                .filter { $0.originType != "usual" }
                            let groupedGeneratedItems = groupItems(generatedItems)
                            if !groupedGeneratedItems.isEmpty {
                                Text("Generated Items").font(.headline).padding([.leading, .top])
                                ForEach(groupedGeneratedItems, id: \.key) { group in
                                    ShoppingListGroupedRow(
                                        name: group.key,
                                        items: group.value,
                                        onToggle: {
                                            toggleAll(items: group.value)
                                        }
                                    )
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                    Divider()
                                }
                            }

                            // Ticked Off Items Section
                            let groupedTickedItems = groupItems(shoppingListManager.tickedOffItems)
                            if !groupedTickedItems.isEmpty {
                                Text("Ticked Off").font(.headline).padding([.leading, .top])
                                ForEach(groupedTickedItems, id: \.key) { group in
                                    TickedOffGroupedRow(
                                        name: group.key,
                                        items: group.value,
                                        onToggle: {
                                            toggleAll(items: group.value)
                                        }
                                    )
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                    Divider()
                                }
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())

                    // Manual Add Item Section
                    VStack(spacing: 8) {
                        Divider()
                        
                        HStack {
                            TextField("Add item to shopping list", text: $newManualItem)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.accent)
                                .cornerRadius(8)
                                .focused($isTextFieldFocused)
                                .submitLabel(.done)
                                .onSubmit {
                                    addManualItem()
                                }
                            
                            Button("Add") {
                                addManualItem()
                            }
                            .disabled(newManualItem.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .buttonStyle(.borderedProminent)
                            .tint(Color.buttonBackground)
                            .foregroundColor(Color.mainText)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("Done") {
                                    isTextFieldFocused = false
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Shopping List")
            .navigationBarTitleDisplayMode(.inline) // Ensure title is centered
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Shopping List")
                        .font(.title) // Larger navigation title
                        .foregroundColor(.black)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !shoppingListManager.tickedOffItems.isEmpty {
                        Button("Clear Ticked Off") {
                            shoppingListManager.clearTickedOffItems()
                        }
                        .foregroundColor(Color.mainText)
                        .background(Color.buttonBackground)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.accent, lineWidth: 2)
                        )
                    }
                }
            }
            .onTapGesture {
                // Dismiss keyboard when tapping outside
                isTextFieldFocused = false
            }
            .onAppear {
                householdManager.loadOrCreateHousehold()
                loadShoppingList()
            }
            .onChange(of: householdManager.household) { oldValue, newValue in
                if let household = newValue {
                    // Use the corrected startOfWeek method that properly handles Monday as first day
                    let startOfWeek = Calendar.current.startOfWeek(for: Date())
                    weekPlanManager.fetchOrCreateWeek(for: startOfWeek, household: household)
                    loadShoppingList()
                }
            }
            .onChange(of: weekPlanManager.weekPlan) { oldValue, newValue in
                loadShoppingList()
            }
        }
    }

    // MARK: - Private Methods
    
    /// Groups items by name (case-insensitive)
    private func groupItems(_ items: [ShoppingListItem]) -> [(key: String, value: [ShoppingListItem])] {
        let grouped = Dictionary(grouping: items) { ($0.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
        // Sort by name
        return grouped.sorted { $0.key < $1.key }
    }
    
    /// Toggles all items in a group
    private func toggleAll(items: [ShoppingListItem]) {
        for item in items {
            shoppingListManager.toggleItem(item)
        }
    }
    
    /// Generates the shopping list from the current week plan
    private func generateShoppingList() {
        shoppingListManager.generateShoppingList(
            for: weekPlanManager.weekPlan,
            household: householdManager.household
        )
    }
    
    /// Loads the shopping list from Core Data
    private func loadShoppingList() {
        shoppingListManager.loadShoppingList(from: weekPlanManager.weekPlan)
    }
    
    /// Adds a manual item to the shopping list
    private func addManualItem() {
        let trimmedItem = newManualItem.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedItem.isEmpty else { return }
        
        shoppingListManager.addManualItem(trimmedItem, to: weekPlanManager.weekPlan)
        newManualItem = ""
        isTextFieldFocused = false // Dismiss keyboard after adding
    }
}

// MARK: - Shopping List Grouped Row
struct ShoppingListGroupedRow: View {
    let name: String
    let items: [ShoppingListItem]
    let onToggle: () -> Void

    var body: some View {
        HStack {
            // Checkbox - show checked if all items are ticked, unchecked if any are unticked
            Image(systemName: allItemsTicked ? "checkmark.circle.fill" : "circle")
                .foregroundColor(allItemsTicked ? .green : .blue)
                .font(.title3)
                .onTapGesture {
                    onToggle()
                }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(displayName)
                        .font(.title3)
                        .fontWeight(.medium)
                    
                    // Count badge
                    if items.count > 1 {
                        Text("×\(items.count)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accent)
                            .cornerRadius(8)
                    }
                }
                
                if let originType = items.first?.originType {
                    Text(originDescription(for: originType, item: items.first))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle()
        }
    }
    
    private var displayName: String {
        return name.capitalized
    }
    
    private var allItemsTicked: Bool {
        return items.allSatisfy { $0.isTicked }
    }
    
    private func originDescription(for originType: String, item: ShoppingListItem?) -> String {
        guard let item = item else { return "" }
        switch originType {
        case "usual":
            return "Usual Item"
        case "meal":
            if let mealName = item.originMeal, let slot = item.originSlot {
                return "\(mealName) (\(slot.capitalized))"
            }
            return "Meal"
        case "manual_slot":
            if let slot = item.originSlot {
                return "Manual (\(slot.capitalized))"
            }
            return "Manual"
        case "manual":
            return "Manual"
        default:
            return "Unknown"
        }
    }
}

// MARK: - Ticked Off Grouped Row
struct TickedOffGroupedRow: View {
    let name: String
    let items: [ShoppingListItem]
    let onToggle: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.title3)
                .onTapGesture {
                    onToggle()
                }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(displayName)
                        .font(.title3)
                        .fontWeight(.medium)
                        .strikethrough()
                        .foregroundColor(.secondary)
                    
                    // Count badge
                    if items.count > 1 {
                        Text("×\(items.count)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green)
                            .cornerRadius(8)
                    }
                }
                
                if let originType = items.first?.originType {
                    Text(originDescription(for: originType, item: items.first))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle()
        }
    }
    
    private var displayName: String {
        return name.capitalized
    }
    
    private func originDescription(for originType: String, item: ShoppingListItem?) -> String {
        guard let item = item else { return "" }
        switch originType {
        case "usual":
            return "Usual Item"
        case "meal":
            if let mealName = item.originMeal, let slot = item.originSlot {
                return "\(mealName) (\(slot.capitalized))"
            }
            return "Meal"
        case "manual_slot":
            if let slot = item.originSlot {
                return "Manual (\(slot.capitalized))"
            }
            return "Manual"
        case "manual":
            return "Manual"
        default:
            return "Unknown"
        }
    }
}

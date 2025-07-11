import SwiftUI

struct ShoppingListView: View {
    @StateObject private var householdManager = HouseholdManager()
    @StateObject private var weekPlanManager = WeekPlanManager()
    @StateObject private var shoppingListManager = ShoppingListManager()

    @State private var newManualItem = ""
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        NavigationView {
            VStack {
                // Generate Shopping List Button
                Button(action: {
                    generateShoppingList()
                }) {
                    HStack {
                        Image(systemName: "cart.badge.plus")
                            .foregroundColor(.white)
                        Text("Generate Shopping List")
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.top)

                List {
                    // Usual Items Section (individual)
                    let usualItems = shoppingListManager.shoppingItems.filter { $0.originType == "usual" }
                    if !usualItems.isEmpty {
                        Section(header: Text("Usual Items").font(.headline)) {
                            ForEach(usualItems, id: \.objectID) { item in
                                HStack {
                                    Image(systemName: item.isTicked ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(item.isTicked ? .green : .blue)
                                        .onTapGesture {
                                            shoppingListManager.toggleItem(item)
                                        }
                                    Text(item.name ?? "")
                                    Spacer()
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    shoppingListManager.toggleItem(item)
                                }
                            }
                        }
                    }

                    // Generated Items Section (individual)
                    let generatedItems = shoppingListManager.shoppingItems.filter { $0.originType != "usual" }
                    if !generatedItems.isEmpty {
                        Section(header: Text("Generated Items").font(.headline)) {
                            ForEach(generatedItems, id: \.objectID) { item in
                                HStack {
                                    Image(systemName: item.isTicked ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(item.isTicked ? .green : .blue)
                                        .onTapGesture {
                                            shoppingListManager.toggleItem(item)
                                        }
                                    Text(item.name ?? "")
                                    Spacer()
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    shoppingListManager.toggleItem(item)
                                }
                            }
                        }
                    }

                    // Ticked Off Items Section (individual)
                    let tickedItems = shoppingListManager.tickedOffItems
                    if !tickedItems.isEmpty {
                        Section(header: Text("Ticked Off").font(.headline)) {
                            ForEach(tickedItems, id: \.objectID) { item in
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .onTapGesture {
                                            shoppingListManager.toggleItem(item)
                                        }
                                    Text(item.name ?? "")
                                        .strikethrough()
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    shoppingListManager.toggleItem(item)
                                }
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
                            .textFieldStyle(RoundedBorderTextFieldStyle())
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
            .navigationTitle("Shopping List")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !shoppingListManager.tickedOffItems.isEmpty {
                        Button("Clear Ticked Off") {
                            shoppingListManager.clearTickedOffItems()
                        }
                        .foregroundColor(.red)
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
            Image(systemName: "circle")
                .foregroundColor(.blue)
                .font(.caption)
                .onTapGesture {
                    onToggle()
                }
            VStack(alignment: .leading, spacing: 2) {
                Text(displayName)
                    .font(.body)
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
        let base = items.first?.name ?? name.capitalized
        let count = items.count
        return count > 1 ? "\(base) x\(count)" : base
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
                .font(.caption)
                .onTapGesture {
                    onToggle()
                }
            VStack(alignment: .leading, spacing: 2) {
                Text(displayName)
                    .strikethrough()
                    .foregroundColor(.secondary)
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
        let base = items.first?.name ?? name.capitalized
        let count = items.count
        return count > 1 ? "\(base) x\(count)" : base
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

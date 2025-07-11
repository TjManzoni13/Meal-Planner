import SwiftUI

struct ShoppingListView: View {
    @StateObject private var householdManager = HouseholdManager()
    @StateObject private var weekPlanManager = WeekPlanManager()
    @StateObject private var shoppingListManager = ShoppingListManager()

    @State private var newManualItem = ""

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
                    // Usual Items Section
                    if !shoppingListManager.shoppingItems.filter({ $0.originType == "usual" }).isEmpty {
                        Section(header: Text("Usual Items").font(.headline)) {
                            ForEach(shoppingListManager.shoppingItems.filter({ $0.originType == "usual" }), id: \.self) { item in
                                ShoppingListItemRow(
                                    item: item,
                                    onToggle: {
                                        shoppingListManager.toggleItem(item)
                                    }
                                )
                            }
                        }
                    }

                    // Generated Items Section
                    let generatedItems = shoppingListManager.shoppingItems.filter({ $0.originType != "usual" })
                    if !generatedItems.isEmpty {
                        Section(header: Text("Generated Items").font(.headline)) {
                            ForEach(generatedItems, id: \.self) { item in
                                ShoppingListItemRow(
                                    item: item,
                                    onToggle: {
                                        shoppingListManager.toggleItem(item)
                                    }
                                )
                            }
                        }
                    }

                    // Ticked Off Items Section
                    if !shoppingListManager.tickedOffItems.isEmpty {
                        Section(header: Text("Ticked Off").font(.headline)) {
                            ForEach(shoppingListManager.tickedOffItems, id: \.self) { item in
                                TickedOffItemRow(
                                    item: item,
                                    onToggle: {
                                        shoppingListManager.toggleItem(item)
                                    }
                                )
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
                        
                        Button("Add") {
                            addManualItem()
                        }
                        .disabled(newManualItem.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
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
    }
}

// MARK: - Shopping List Item Row
struct ShoppingListItemRow: View {
    let item: ShoppingListItem
    let onToggle: () -> Void

    var body: some View {
        HStack {
            // Checkbox
            Image(systemName: "circle")
                .foregroundColor(.blue)
                .font(.caption)
                .onTapGesture {
                    onToggle()
                }
            
            // Item name
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name ?? "")
                    .font(.body)
                
                // Show origin information
                if let originType = item.originType {
                    Text(originDescription(for: originType, item: item))
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
    
    /// Returns a description of the item's origin
    private func originDescription(for originType: String, item: ShoppingListItem) -> String {
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

// MARK: - Ticked Off Item Row
struct TickedOffItemRow: View {
    let item: ShoppingListItem
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
                Text(item.name ?? "")
                    .strikethrough()
                    .foregroundColor(.secondary)
                
                // Show origin information
                if let originType = item.originType {
                    Text(originDescription(for: originType, item: item))
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
    
    /// Returns a description of the item's origin
    private func originDescription(for originType: String, item: ShoppingListItem) -> String {
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

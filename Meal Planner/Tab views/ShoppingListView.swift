import SwiftUI

struct ShoppingListView: View {
    @StateObject private var householdManager = HouseholdManager()
    @StateObject private var weekPlanManager = WeekPlanManager()
    @StateObject private var builder = ShoppingListBuilder()

    @State private var newManualItem = ""
    @State private var showingAddItem = false

    var body: some View {
        NavigationView {
            VStack {
                List {
                    // Everyday Items Section
                    Section(header: Text("Everyday Items").font(.headline)) {
                        ForEach(builder.everydayItems, id: \.self) { item in
                            if !builder.isTicked(item) {
                                ShoppingListItemRow(
                                    item: item,
                                    isDuplicate: builder.isDuplicate(item),
                                    duplicateColor: builder.duplicateColor(for: item),
                                    onToggle: {
                                        builder.toggleItem(item)
                                    }
                                )
                            }
                        }
                    }

                    // Auto-generated Shopping List
                    Section(header: Text("From Meal Plan").font(.headline)) {
                        ForEach(builder.mealItems, id: \.self) { item in
                            if !builder.isTicked(item) {
                                ShoppingListItemRow(
                                    item: item,
                                    isDuplicate: builder.isDuplicate(item),
                                    duplicateColor: builder.duplicateColor(for: item),
                                    onToggle: {
                                        builder.toggleItem(item)
                                    }
                                )
                            }
                        }
                    }

                    // Manual Items
                    if !builder.manualItems.isEmpty {
                        Section(header: Text("Manual Items").font(.headline)) {
                            ForEach(builder.manualItems, id: \.self) { item in
                                if !builder.isTicked(item) {
                                    ShoppingListItemRow(
                                        item: item,
                                        isDuplicate: builder.isDuplicate(item),
                                        duplicateColor: builder.duplicateColor(for: item),
                                        onToggle: {
                                            builder.toggleItem(item)
                                        }
                                    )
                                }
                            }
                        }
                    }

                    // Ticked Off Items
                    if !builder.tickedOff.isEmpty {
                        Section(header: Text("Ticked Off").font(.headline)) {
                            ForEach(Array(builder.tickedOff), id: \.self) { item in
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                    
                                    Text(item.name)
                                        .strikethrough()
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Text(item.source)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    builder.toggleItem(item)
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
            .onAppear {
                householdManager.loadOrCreateHousehold()
            }
            .onChange(of: householdManager.household) { _, household in
                if let household = household {
                    let startOfWeek = Calendar.current.startOfWeek(for: Date())
                    weekPlanManager.fetchOrCreateWeek(for: startOfWeek, household: household)
                }
            }
            .onChange(of: weekPlanManager.weekPlan) { _, plan in
                builder.build(from: plan, household: householdManager.household)
            }
            .onReceive(weekPlanManager.objectWillChange) { _ in
                // Rebuild shopping list when weekPlanManager changes (e.g., when "already have" is toggled)
                print("WeekPlanManager changed, rebuilding shopping list")
                builder.build(from: weekPlanManager.weekPlan, household: householdManager.household)
            }
            .onAppear {
                // Rebuild shopping list when view appears
                builder.build(from: weekPlanManager.weekPlan, household: householdManager.household)
            }
        }
    }

    private func addManualItem() {
        let trimmedItem = newManualItem.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedItem.isEmpty else { return }
        
        builder.addManualItem(trimmedItem)
        newManualItem = ""
    }
}

// MARK: - Shopping List Item Row
struct ShoppingListItemRow: View {
    let item: ShoppingListItem
    let isDuplicate: Bool
    let duplicateColor: Color
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
            
            // Item name with duplicate highlighting
            Text(item.name)
                .background(
                    isDuplicate ? duplicateColor.opacity(0.3) : Color.clear
                )
                .cornerRadius(4)
            
            Spacer()
            
            // Source and duplicate indicator
            HStack(spacing: 4) {
                if isDuplicate {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.caption2)
                }
                
                Text(item.source)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle()
        }
    }
}

import SwiftUI

struct ShoppingListView: View {
    @StateObject private var householdManager = HouseholdManager()
    @StateObject private var weekPlanManager = WeekPlanManager()
    @StateObject private var builder = ShoppingListBuilder()

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("To Buy")) {
                    ForEach(builder.items, id: \.self) { item in
                        if !builder.isTicked(item) {
                            HStack {
                                Text(item.name)
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

                if !builder.tickedOff.isEmpty {
                    Section(header: Text("Ticked Off")) {
                        ForEach(Array(builder.tickedOff), id: \.self) { item in
                            HStack {
                                Text(item.name)
                                    .strikethrough()
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
            .navigationTitle("Shopping")
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
        }
    }
}

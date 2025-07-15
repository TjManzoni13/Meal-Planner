import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Int = 0
    var body: some View {
        TabView(selection: $selectedTab) {
            WeeklyMealPlannerView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Plan", systemImage: "calendar")
                }
                .tag(0)

            ShoppingListView()
                .tabItem {
                    Label("Shop", systemImage: "cart")
                }
                .tag(1)

            MealsAndUsualsView()
                .tabItem {
                    Label("Meals", systemImage: "fork.knife")
                }
                .tag(2)

            HouseholdView()
                .tabItem {
                    Label("Household", systemImage: "person.2.fill")
                }
                .tag(3)
        }
        // Set the background and text color for the tab view
        .background(Color.appBackground.ignoresSafeArea())
        .foregroundColor(Color.mainText)
    }
}
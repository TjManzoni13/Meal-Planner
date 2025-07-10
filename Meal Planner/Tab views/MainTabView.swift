import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            WeeklyMealPlannerView()
                .tabItem {
                    Label("Plan", systemImage: "calendar")
                }

            ShoppingListView()
                .tabItem {
                    Label("Shop", systemImage: "cart")
                }

            MealsAndUsualsView()
                .tabItem {
                    Label("Meals", systemImage: "fork.knife")
                }

            HouseholdView()
                .tabItem {
                    Label("Household", systemImage: "person.2.fill")
                }
        }
    }
}